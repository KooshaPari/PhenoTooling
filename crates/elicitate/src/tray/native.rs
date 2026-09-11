//! Real OS tray backend — compiled only with `--features tray-native`.
//!
//! Uses `tray-icon` crate (NSStatusItem on macOS, Shell_NotifyIcon on Windows,
//! libappindicator on Linux). The `TrayIcon` is created and owned by a dedicated
//! OS thread because `tray-icon`'s internal state is `!Send + !Sync` on macOS
//! (Objective-C refs considered single-threaded by ARC). All public methods post
//! commands over a channel; the owner thread executes them serially.

use super::{MenuAction, TrayConfig, TrayError, TrayEvent, Tray, TrayResult};
use std::sync::mpsc::{channel, Sender};
use tray_icon::{
    menu::{Menu, MenuEvent, MenuItem, PredefinedMenuItem},
    Icon, TrayIconBuilder,
};

/// Commands sent to the dedicated tray-icon owning thread.
enum TrayCmd {
    SetBadge { text: String },
    SetTooltip { text: String },
    Shutdown,
}

/// Real OS tray. Backed by `tray-icon` (NSStatusItem on macOS,
/// Shell_NotifyIcon on Windows, libappindicator on Linux).
pub struct NativeTray {
    cmd_tx: Sender<TrayCmd>,
    ev_rx: std::sync::Mutex<std::sync::mpsc::Receiver<TrayEvent>>,
    backend: &'static str,
    /// Stable URL the daemon serves on. Captured here so `try_recv`
    /// consumers (the daemon's tray event loop) can resolve click
    /// targets without a separate getter on the Tray trait.
    inbox_url: String,
}

impl NativeTray {
    pub fn new(cfg: TrayConfig) -> TrayResult<Self> {
        let backend: &'static str = {
            #[cfg(target_os = "macos")]
            { "nsstatusitem" }
            #[cfg(target_os = "windows")]
            { "shell_notifyicon" }
            #[cfg(target_os = "linux")]
            { "libappindicator" }
            #[cfg(not(any(target_os = "macos", target_os = "windows", target_os = "linux")))]
            { "unsupported" }
        };

        let inbox_url = cfg.inbox_url.clone();
        let tooltip = cfg.tooltip.clone();
        let initial = cfg.initial_badge.clone();

        let (ev_tx, ev_rx) = channel::<TrayEvent>();
        let (cmd_tx, cmd_rx) = channel::<TrayCmd>();

        std::thread::Builder::new()
            .name("elicitate-tray".into())
            .spawn(move || {
                let result = Self::run_owning_thread(tooltip, initial, cmd_rx, ev_tx);
                if let Err(e) = result {
                    tracing::warn!(error = %e, "tray owner thread exited with error");
                }
            })
            .map_err(|e| TrayError::Backend(format!("failed to spawn tray thread: {e}")))?;

        Ok(Self {
            cmd_tx,
            ev_rx: std::sync::Mutex::new(ev_rx),
            backend,
            inbox_url,
        })
    }

    fn run_owning_thread(
        tooltip: String,
        initial: String,
        cmd_rx: std::sync::mpsc::Receiver<TrayCmd>,
        ev_tx: Sender<TrayEvent>,
    ) -> TrayResult<()> {
        let icon = make_placeholder_icon()?;

        let menu = Menu::new();
        let open_inbox = MenuItem::with_id(
            MenuAction::OpenInbox.id(),
            MenuAction::OpenInbox.label(),
            true,
            None,
        );
        let open_latest = MenuItem::with_id(
            MenuAction::OpenLatest.id(),
            MenuAction::OpenLatest.label(),
            true,
            None,
        );
        let toggle_quiet = MenuItem::with_id(
            MenuAction::ToggleQuiet.id(),
            MenuAction::ToggleQuiet.label(),
            true,
            None,
        );
        let sep = PredefinedMenuItem::separator();
        let quit = MenuItem::with_id(
            MenuAction::Quit.id(),
            MenuAction::Quit.label(),
            true,
            None,
        );
        menu.append(&open_inbox).map_err(map_err)?;
        menu.append(&open_latest).map_err(map_err)?;
        menu.append(&toggle_quiet).map_err(map_err)?;
        menu.append(&sep).map_err(map_err)?;
        menu.append(&quit).map_err(map_err)?;

        let mut builder = TrayIconBuilder::new()
            .with_tooltip(tooltip)
            .with_icon(icon)
            .with_menu(Box::new(menu));
        if !initial.is_empty() {
            builder = builder.with_title(initial);
        }
        let tray = builder
            .build()
            .map_err(|e| TrayError::NotAvailable(e.to_string()))?;

        loop {
            // Drain any pending commands.
            loop {
                match cmd_rx.try_recv() {
                    Ok(TrayCmd::SetBadge { text }) => {
                        let _ = tray.set_title(Some(text.clone()));
                        let tooltip = format!("elicitate inbox · {} pending", text);
                        let _ = tray.set_tooltip(Some(tooltip));
                    }
                    Ok(TrayCmd::SetTooltip { text }) => {
                        let _ = tray.set_tooltip(Some(text));
                    }
                    Ok(TrayCmd::Shutdown) => {
                        drop(tray);
                        return Ok(());
                    }
                    Err(std::sync::mpsc::TryRecvError::Empty) => break,
                    Err(std::sync::mpsc::TryRecvError::Disconnected) => {
                        drop(tray);
                        return Ok(());
                    }
                }
            }

            // Forward tray-icon click events.
            if let Ok(ev) = tray_icon::TrayIconEvent::receiver().try_recv() {
                let mapped = match ev {
                    tray_icon::TrayIconEvent::Click { .. } => Some(TrayEvent::Click),
                    tray_icon::TrayIconEvent::DoubleClick { .. } => {
                        Some(TrayEvent::DoubleClick)
                    }
                    _ => None,
                };
                if let Some(m) = mapped {
                    let _ = ev_tx.send(m);
                }
            }

            // Forward menu events.
            if let Ok(ev) = MenuEvent::receiver().try_recv() {
                let mapped = TrayEvent::MenuItem {
                    id: ev.id.as_ref().to_string(),
                };
                let _ = ev_tx.send(mapped);
            }

            std::thread::sleep(std::time::Duration::from_millis(50));
        }
    }
}

impl Tray for NativeTray {
    fn set_badge(&self, text: &str) -> TrayResult<()> {
        self.cmd_tx
            .send(TrayCmd::SetBadge {
                text: text.to_string(),
            })
            .map_err(|e| TrayError::Backend(format!("tray channel closed: {e}")))
    }

    fn set_tooltip(&self, text: &str) -> TrayResult<()> {
        self.cmd_tx
            .send(TrayCmd::SetTooltip {
                text: text.to_string(),
            })
            .map_err(|e| TrayError::Backend(format!("tray channel closed: {e}")))
    }

    fn notify(&self, _title: &str, _body: &str) -> TrayResult<()> {
        // tray-icon doesn't expose native notifications directly.
        // The daemon's notify.rs channels handle cross-platform notifications.
        Ok(())
    }

    fn try_recv(&self) -> Option<TrayEvent> {
        self.ev_rx.lock().ok()?.try_recv().ok()
    }

    fn shutdown(&self) -> TrayResult<()> {
        let _ = self.cmd_tx.send(TrayCmd::Shutdown);
        Ok(())
    }

    fn backend_name(&self) -> &'static str {
        self.backend
    }

    fn inbox_url(&self) -> Option<&str> {
        Some(&self.inbox_url)
    }
}

fn make_placeholder_icon() -> TrayResult<Icon> {
    // 16x16 RGBA, opaque neutral grey dot.
    const SIZE: u32 = 16;
    let mut rgba = Vec::with_capacity((SIZE * SIZE * 4) as usize);
    for y in 0..SIZE {
        for x in 0..SIZE {
            let dx = x as i32 - 8;
            let dy = y as i32 - 8;
            let inside = (dx * dx + dy * dy) <= 49;
            let (r, g, b, a) = if inside {
                if (dx + dy) % 2 == 0 {
                    (40u8, 40, 40, 255)
                } else {
                    (60, 60, 60, 255)
                }
            } else {
                (0, 0, 0, 0)
            };
            rgba.extend_from_slice(&[r, g, b, a]);
        }
    }
    Icon::from_rgba(rgba, SIZE, SIZE).map_err(|e| TrayError::Icon(e.to_string()))
}

fn map_err<E: std::fmt::Display>(e: E) -> TrayError {
    TrayError::Backend(e.to_string())
}
