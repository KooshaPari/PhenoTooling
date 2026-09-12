//! `phinbox-app` — macOS .app bundle entry point.
//!
//! Launches the Phinbox daemon with tray icon enabled and opens the
//! inbox in the default browser. Compiled with `--features tray-native`.

use std::path::PathBuf;

fn main() {
    let inbox_dir: PathBuf = std::env::var("PHINBOX_INBOX_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs_bridge().join("Phinbox")
        });

    let port: u16 = std::env::var("PHINBOX_PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(7117);

    // Ensure inbox directory exists
    let _ = std::fs::create_dir_all(&inbox_dir);

    let notify = phinbox::NotifyChannels {
        imessage_target: std::env::var("PHINBOX_IMESSAGE_TARGET").ok(),
        email_target: std::env::var("PHINBOX_EMAIL_TARGET").ok(),
        webhook_url: std::env::var("PHINBOX_WEBHOOK_URL").ok(),
        native: true,
    };

    let cfg = phinbox::inbox::daemon::DaemonConfig {
        inbox_root: inbox_dir,
        port,
        bind: "127.0.0.1".parse().unwrap(),
        notify,
        enable_tray: true,
    };

    let handle = match phinbox::inbox::daemon::start_daemon(cfg) {
        Ok(h) => h,
        Err(e) => {
            eprintln!("phinbox: failed to start daemon: {e}");
            std::process::exit(1);
        }
    };

    // Open the inbox in the default browser
    let url = format!("http://127.0.0.1:{}/inbox/", handle.port);
    let _ = phinbox::open_in_default_browser(&url);

    eprintln!("phinbox: daemon running on http://127.0.0.1:{}", handle.port);
    eprintln!("phinbox: inbox opened in browser");

    // Block until termination signal
    daemon_shutdown_signal();
    let _ = handle.stop();
}

fn dirs_bridge() -> PathBuf {
    // Simple home directory detection
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/tmp"))
        .join(".phinbox")
}

fn daemon_shutdown_signal() {
    use std::sync::{Arc, Condvar, Mutex};
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
