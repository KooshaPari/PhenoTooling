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

    let handle = match phinbox::inbox::daemon::start_daemon(cfg) {
        Ok(h) => h,
        Err(e) => {
            eprintln!("phinbox: failed to start daemon: {e}");
            std::process::exit(1);
        }
    };

    // Open inbox in browser
    let url = format!("http://127.0.0.1:{}/inbox/", handle.port);
    let _ = phinbox::open_in_default_browser(&url);

    eprintln!("phinbox: daemon running on http://127.0.0.1:{}", handle.port);

    // On macOS: create tray on main thread and run Cocoa event loop
    #[cfg(target_os = "macos")]
    {
        create_tray_and_run_event_loop(handle, port);
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
    port: u16,
) {
    use objc2_app_kit::{NSApplication, NSApplicationActivationPolicy};
    use objc2_foundation::MainThreadMarker;

    let mtm = match MainThreadMarker::new() {
        Some(m) => m,
        None => {
            eprintln!("phinbox: not on main thread, cannot create tray");
            daemon_shutdown_signal();
            let _ = handle.stop();
            return;
        }
    };

    // Initialize NSApplication (required for tray icon event loop)
    let app = NSApplication::sharedApplication(mtm);
    app.setActivationPolicy(NSApplicationActivationPolicy::Accessory);

    // Create tray on main thread (has MainThreadMarker)
    let tray_url = format!("http://127.0.0.1:{}", port);
    let tray_cfg = phinbox::TrayConfig::new(tray_url, &handle.inbox_root);
    let tray = match phinbox::build_tray(tray_cfg) {
        Ok(t) => t,
        Err(e) => {
            eprintln!("phinbox: tray creation failed: {e}");
            daemon_shutdown_signal();
            let _ = handle.stop();
            return;
        }
    };

    // Spawn tray event pump on background thread
    let shutdown = Arc::new(std::sync::atomic::AtomicBool::new(false));
    {
        let tray_ref = tray.clone();
        let shutdown_ref = shutdown.clone();
        let fallback = format!("http://127.0.0.1:{}", port);
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

    // Cleanup
    shutdown.store(true, std::sync::atomic::Ordering::SeqCst);
    let _ = tray.shutdown();
    let _ = handle.stop();
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
