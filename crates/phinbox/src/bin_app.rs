//! `phinbox-app` — macOS .app bundle entry point.
//!
//! Launches the Phinbox daemon with tray icon enabled and opens the
//! inbox in the default browser. Compiled with `--features tray-native`.
//!
//! On macOS, the tray icon (NSStatusItem) MUST be created on the main
//! thread, and the main thread must run the Cocoa event loop. This binary
//! handles that correctly:
//!
//! 1. Main thread: initialize NSApplication, create tray, run event loop
//! 2. Background thread: start the HTTP daemon (no tray -- the main thread owns it)

use std::path::PathBuf;
use std::sync::{Arc, Condvar, Mutex};

fn main() {
    let inbox_dir: PathBuf = std::env::var("PHINBOX_INBOX_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| dirs_bridge().join("Phinbox"));

    let port: u16 = std::env::var("PHINBOX_PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(7117);

    let _ = std::fs::create_dir_all(&inbox_dir);

    let notify = phinbox::NotifyChannels {
        imessage_target: std::env::var("PHINBOX_IMESSAGE_TARGET").ok(),
        email_target: std::env::var("PHINBOX_EMAIL_TARGET").ok(),
        webhook_url: std::env::var("PHINBOX_WEBHOOK_URL").ok(),
        native: true,
    };

    // Start daemon on background thread (without tray -- we create it on main)
    let cfg = phinbox::inbox::daemon::DaemonConfig {
        inbox_root: inbox_dir,
        port,
        bind: "127.0.0.1".parse().unwrap(),
        notify,
        enable_tray: false, // we create the tray on the main thread
    };

    // Try to start the daemon. If one is already running on this port,
    // read the lockfile to reuse its port/inbox_root for the tray.
    let (handle, owns_daemon) = match phinbox::inbox::daemon::start_daemon(cfg.clone())
    {
        Ok(h) => (h, true),
        Err(e) => {
            // Check if this is the "already running" case
            let msg = e.to_string();
            if msg.contains("daemon already running") {
                // Read the existing lockfile to get port + root
                if let Some(lf) =
                    phinbox::inbox::daemon::lockfile::read_lockfile(&cfg.inbox_root)
                {
                    eprintln!(
                        "phinbox: reusing existing daemon on port {}",
                        lf.port
                    );
                    (
                        phinbox::inbox::daemon::DaemonHandle {
                            port: lf.port,
                            inbox_root: lf.root,
                            bind_addr: lf.bind,
                            lockfile: cfg
                                .inbox_root
                                .join(phinbox::inbox::daemon::lockfile::LOCKFILE_NAME),
                            shutdown: std::sync::Arc::new(
                                std::sync::atomic::AtomicBool::new(false),
                            ),
                        },
                        false, // we don't own this daemon
                    )
                } else {
                    eprintln!("phinbox: daemon running but lockfile unreadable: {e}");
                    std::process::exit(1);
                }
            } else {
                eprintln!("phinbox: failed to start daemon: {e}");
                std::process::exit(1);
            }
        }
    };

    // Open inbox in the native Swift helper window
    launch_inbox_helper(handle.port);

    eprintln!("phinbox: daemon running on http://127.0.0.1:{}", handle.port);

    // On macOS: create tray on main thread and run Cocoa event loop
    #[cfg(target_os = "macos")]
    {
        create_tray_and_run_event_loop(handle, owns_daemon);
    }

    // On other platforms: just block until shutdown
    #[cfg(not(target_os = "macos"))]
    {
        daemon_shutdown_signal();
        let _ = handle.stop();
    }
}

#[cfg(target_os = "macos")]
fn create_tray_and_run_event_loop(
    handle: phinbox::inbox::daemon::DaemonHandle,
    owns_daemon: bool,
) {
    use objc2_app_kit::{NSApplication, NSApplicationActivationPolicy};
    use objc2_foundation::MainThreadMarker;

    let mtm = match MainThreadMarker::new() {
        Some(m) => m,
        None => {
            eprintln!("phinbox: not on main thread, cannot create tray");
            daemon_shutdown_signal();
            if owns_daemon { let _ = handle.stop(); }
            return;
        }
    };

    // Initialize NSApplication (required for tray icon event loop)
    let app = NSApplication::sharedApplication(mtm);
    app.setActivationPolicy(NSApplicationActivationPolicy::Accessory);

    // Create tray on main thread (has MainThreadMarker)
    let tray_url = format!("http://127.0.0.1:{}", handle.port);
    let tray_cfg = phinbox::TrayConfig::new(tray_url, &handle.inbox_root);
    let tray = match phinbox::build_tray(tray_cfg) {
        Ok(t) => t,
        Err(e) => {
            eprintln!("phinbox: tray creation failed: {e}");
            daemon_shutdown_signal();
            if owns_daemon { let _ = handle.stop(); }
            return;
        }
    };

    // Spawn tray event pump on background thread
    let shutdown = Arc::new(std::sync::atomic::AtomicBool::new(false));
    {
        let tray_ref = tray.clone();
        let shutdown_ref = shutdown.clone();
        let fallback = format!("http://127.0.0.1:{}", handle.port);
        std::thread::Builder::new()
            .name("phinbox-tray-events".into())
            .spawn(move || {
                phinbox::inbox::daemon::notifier::run_tray_loop(
                    tray_ref.as_ref(),
                    &shutdown_ref,
                    &fallback,
                );
            })
            .ok();
    }

    // Run Cocoa event loop on main thread (blocks until app terminates)
    // This keeps NSStatusItem alive and receiving click/menu events.
    app.run();

    // Cleanup — only stop daemon if we started it
    shutdown.store(true, std::sync::atomic::Ordering::SeqCst);
    let _ = tray.shutdown();
    if owns_daemon {
        let _ = handle.stop();
    }
}

/// Launch the native Swift inbox helper window.
///
/// Looks for `inbox-helper` in these locations (first found wins):
/// 1. Same directory as the running binary (development / flat layout)
/// 2. `../Resources/inbox-helper` relative to the binary (inside .app bundle)
fn launch_inbox_helper(port: u16) {
    use std::process::Command;

    let exe = std::env::current_exe().ok();
    let exe_dir = exe.as_ref().and_then(|p| p.parent());

    let candidates: Vec<String> = {
        let mut v = Vec::new();
        if let Some(dir) = exe_dir {
            // Flat layout: binary and helper side by side
            v.push(dir.join("inbox-helper").to_string_lossy().into_owned());
            // .app bundle: helper in ../Resources/
            v.push(
                dir.join("../Resources/inbox-helper")
                    .to_string_lossy()
                    .into_owned(),
            );
        }
        // Fallback: hope it's on PATH
        v.push("inbox-helper".into());
        v
    };

    for path in &candidates {
        if std::path::Path::new(path).exists() {
            let url = format!("http://127.0.0.1:{}/inbox/", port);
            match Command::new(path).arg(&url).spawn() {
                Ok(child) => {
                    eprintln!(
                        "phinbox: launched inbox helper (PID {})",
                        child.id()
                    );
                    // Detach — let it run independently
                    std::mem::forget(child);
                    return;
                }
                Err(e) => {
                    eprintln!("phinbox: failed to launch {path}: {e}");
                }
            }
        }
    }
    eprintln!("phinbox: inbox-helper not found, falling back to browser");
    let url = format!("http://127.0.0.1:{}/inbox/", port);
    let _ = phinbox::open_in_default_browser(&url);
}

fn dirs_bridge() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/tmp"))
        .join(".phinbox")
}

fn daemon_shutdown_signal() {
    let state = Arc::new((Mutex::new(false), Condvar::new()));
    let state_for_thread = state.clone();
    std::thread::spawn(move || {
        wait_for_termination();
        let (lock, cv) = &*state_for_thread;
        *lock.lock().unwrap() = true;
        cv.notify_all();
    });
    let (lock, cv) = &*state;
    let mut signaled = lock.lock().unwrap();
    while !*signaled {
        signaled = cv.wait(signaled).unwrap();
    }
}

#[cfg(unix)]
fn wait_for_termination() {
    use std::os::raw::c_int;
    extern "C" {
        fn signal(sig: c_int, handler: extern "C" fn(c_int)) -> extern "C" fn(c_int);
    }
    extern "C" fn handler(_sig: c_int) {
        std::process::exit(0);
    }
    unsafe {
        signal(2, handler); // SIGINT
        signal(15, handler); // SIGTERM
        signal(1, handler); // SIGHUP
    }
    loop {
        std::thread::park();
    }
}
