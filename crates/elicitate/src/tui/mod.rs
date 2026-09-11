//! Terminal UI inbox viewer (`elicitate inbox --tui`).
//!
//! When the daemon has queued prompts that are blocking an agent, the user
//! needs a way to **see and answer** them without leaving the terminal. The
//! TUI viewer renders a split-pane terminal interface over the same on-disk
//! inbox the daemon writes to, with live polling so newly enqueued requests
//! appear immediately.
//!
//! ## Layout
//!
//! ```text
//! ┌─ inbox · ~/.../inbox ───────────────────────────────────────┐
//! │ pending (3)                                               ↑↓│
//! │  ▶ req-1  (2s)   Need to ship?                  [P] Info   │
//! │    req-2  (8s)   Confirm dangerous op            [P] Warn   │
//! │    req-3  (2m)   Choose a region                 [P] Info   │
//! ├──────────────────────────────────────────────────────────────┤
//! │ title     Need to ship?                                     │
//! │ question  Are we ready to ship v0.5 by Friday?             │
//! │ field     boolean — Confirm? (default yes)                 │
//! │ urgency   info · ttl 10m                                    │
//! │ origin    agent@host (pid 12345)                           │
//! │                                                              │
//! │ [a] answer · [o] open in browser · [d] dismiss · q quit    │
//! └──────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## Submodules
//!
//! - `state` — `TuiOutcome`, `ListEntry`, `ViewerState`, snapshot logic
//! - `render` — ratatui widget builders for each pane
//! - `event` — keyboard handling, terminal mode management, run loop

use std::io::stdout;
use std::path::Path;

use ratatui::backend::CrosstermBackend;
use ratatui::Terminal;

pub mod event;
pub mod render;
pub mod state;

pub use state::{position_of, snapshot_inbox, ListEntry, TuiOutcome, ViewerState};

/// Run the TUI viewer to completion. Returns the outcome (quit / answered /
/// dismissed) or `TuiOutcome::NoTty` if the terminal refused raw mode.
pub fn run(inbox_root: &Path, follow: bool) -> Result<TuiOutcome, String> {
    let raw_ok = match event::enter_raw_mode() {
        Ok(b) => b,
        Err(e) => return Err(e),
    };
    if !raw_ok {
        return Ok(TuiOutcome::NoTty);
    }
    let backend = CrosstermBackend::new(stdout());
    let mut terminal = match Terminal::new(backend) {
        Ok(t) => t,
        Err(e) => {
            event::leave_raw_mode();
            return Err(format!("Terminal::new: {e}"));
        }
    };

    let watcher = if follow {
        Some(crate::inbox::change::InboxChangeBus::global().subscribe())
    } else {
        None
    };

    let result = event::run_loop(&mut terminal, inbox_root, watcher);
    event::leave_raw_mode();
    result
}

/// Plain-text fallback used when no TTY is available. Renders a numbered
/// list of pending requests to stdout so the user can still see what was
/// queued, and prints a hint to invoke `elicitate inbox --tui` on a TTY.
pub fn render_plain(inbox_root: &Path) -> Result<usize, String> {
    let entries = snapshot_inbox(inbox_root)?;
    let count = entries.len();
    println!("elicitate inbox (plain-text mode — no TTY)");
    println!("hint: run `elicitate inbox --tui` on a terminal for the full UI");
    println!();
    if entries.is_empty() {
        println!("(no pending requests)");
        return Ok(count);
    }
    for (i, e) in entries.iter().enumerate() {
        println!(
            "  {:>3}. [{}] {:<14}  {:<40}  ({})",
            i + 1,
            e.state_badge,
            state::truncate(&e.request_id, 14),
            e.title,
            e.age_label
        );
    }
    println!();
    println!(
        "open a request:  elicitate inbox --open --show <id>"
    );
    Ok(count)
}

/// Build a `TuiOutcome::Answered` for the given request_id — exposed so the
/// CLI can construct the outcome after an external answer step.
#[must_use]
pub fn outcome_answered(id: impl Into<String>) -> TuiOutcome {
    TuiOutcome::Answered(id.into())
}

// ----------------- tests -------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use crate::inbox::RequestOrigin;
    use crate::spec::{FieldSpec, PromptSpec, Urgency};
    use crate::inbox::{PendingRequest, RequestState};
    use crate::tui::state::{build_entry, format_age, sort_entries, truncate};

    fn sample_spec() -> PromptSpec {
        PromptSpec {
            title: "Ship v0.5".to_string(),
            question: "Are we ready to ship?".to_string(),
            field: FieldSpec::Boolean {
                label: "Confirm?".to_string(),
                default: Some(true),
            },
            notes: None,
            buttons: None,
            urgency: Urgency::Warning,
            timeout_secs: 600,
            request_id: Some("req-1".to_string()),
        }
    }

    fn sample_origin() -> RequestOrigin {
        RequestOrigin {
            hostname: "host".to_string(),
            process: "agent".to_string(),
            pid: 42,
            callback: None,
        }
    }

    #[test]
    fn viewer_state_default_has_no_entries_and_focus_on_list() {
        let s = ViewerState::default();
        assert!(s.entries.is_empty());
        assert!(s.focus_on_list);
        assert_eq!(s.selected, 0);
    }

    #[test]
    fn move_down_clamped_to_last_entry() {
        let mut s = ViewerState::default();
        s.entries = vec![
            ListEntry {
                request_id: "a".into(),
                title: "a".into(),
                urgency_label: "Info".into(),
                state_badge: "[P]".into(),
                age_label: "1s".into(),
                is_terminal: false,
            },
            ListEntry {
                request_id: "b".into(),
                title: "b".into(),
                urgency_label: "Info".into(),
                state_badge: "[P]".into(),
                age_label: "2s".into(),
                is_terminal: false,
            },
        ];
        s.move_down(1);
        assert_eq!(s.selected, 1);
        s.move_down(5);
        assert_eq!(s.selected, 1);
    }

    #[test]
    fn move_up_floors_at_zero() {
        let mut s = ViewerState::default();
        s.entries = vec![ListEntry {
            request_id: "a".into(),
            title: "a".into(),
            urgency_label: "Info".into(),
            state_badge: "[P]".into(),
            age_label: "1s".into(),
            is_terminal: false,
        }];
        s.move_up(5);
        assert_eq!(s.selected, 0);
    }

    #[test]
    fn toggle_focus_flips() {
        let mut s = ViewerState::default();
        assert!(s.focus_on_list);
        s.toggle_focus();
        assert!(!s.focus_on_list);
        s.toggle_focus();
        assert!(s.focus_on_list);
    }

    #[test]
    fn format_age_units() {
        assert_eq!(format_age(0), "0s");
        assert_eq!(format_age(45_000), "45s");
        assert_eq!(format_age(120_000), "2m");
        assert_eq!(format_age(3_600_000), "1h");
        assert_eq!(format_age(86_400_000), "1d");
    }

    #[test]
    fn truncate_short_string_is_unchanged() {
        assert_eq!(truncate("hello", 10), "hello");
    }

    #[test]
    fn truncate_long_string_is_truncated() {
        let s = "a".repeat(50);
        let out = truncate(&s, 10);
        assert_eq!(out.chars().count(), 10);
        assert!(out.ends_with('…'));
    }

    #[test]
    fn build_entry_marks_terminal_states() {
        let req = PendingRequest {
            request_id: "r".into(),
            origin: sample_origin(),
            spec: sample_spec(),
            queued_at_ms: 1_000_000,
            expires_at_ms: u64::MAX,
            state: RequestState::Answered,
            response: None,
            notified_via: vec![],
            metadata: serde_json::Map::new(),
        };
        let e = build_entry(&req, 1_001_000);
        assert_eq!(e.state_badge, "[A]");
        assert!(e.is_terminal);
        assert_eq!(e.age_label, "1s");
    }

    #[test]
    fn sort_entries_pending_first_then_terminal() {
        let mut entries = vec![
            ListEntry {
                request_id: "old-terminal".into(),
                title: "old".into(),
                urgency_label: "Info".into(),
                state_badge: "[A]".into(),
                age_label: "5s".into(),
                is_terminal: true,
            },
            ListEntry {
                request_id: "new-pending".into(),
                title: "new".into(),
                urgency_label: "Info".into(),
                state_badge: "[P]".into(),
                age_label: "1s".into(),
                is_terminal: false,
            },
        ];
        sort_entries(&mut entries);
        assert_eq!(entries[0].request_id, "new-pending");
        assert_eq!(entries[1].request_id, "old-terminal");
    }

    #[test]
    fn position_of_finds_request_id() {
        let entries = vec![
            ListEntry {
                request_id: "a".into(),
                title: "a".into(),
                urgency_label: "Info".into(),
                state_badge: "[P]".into(),
                age_label: "1s".into(),
                is_terminal: false,
            },
            ListEntry {
                request_id: "b".into(),
                title: "b".into(),
                urgency_label: "Info".into(),
                state_badge: "[P]".into(),
                age_label: "2s".into(),
                is_terminal: false,
            },
        ];
        assert_eq!(position_of(&entries, "b"), Some(1));
        assert_eq!(position_of(&entries, "z"), None);
    }

    #[test]
    fn field_summary_includes_label_and_kind() {
        let s = render::field_summary(&FieldSpec::Boolean {
            label: "Ready?".into(),
            default: None,
        });
        assert!(s.contains("boolean"));
        assert!(s.contains("Ready?"));
    }

    #[test]
    fn render_detail_lines_includes_origin_and_urgency() {
        let spec = sample_spec();
        let origin = sample_origin();
        let lines = render::render_detail_lines(&spec, &origin);
        let flat: String = lines
            .iter()
            .map(|l| l.to_string())
            .collect::<Vec<_>>()
            .join("\n");
        assert!(flat.contains("urgency"));
        assert!(flat.contains("origin"));
        assert!(flat.contains("agent@host"));
    }

    #[test]
    fn snapshot_inbox_empty_when_dir_missing() {
        let tmp = tempfile::tempdir().unwrap();
        let entries = snapshot_inbox(tmp.path()).unwrap();
        assert!(entries.is_empty());
    }

    #[test]
    fn snapshot_inbox_returns_sorted_entries() {
        let tmp = tempfile::tempdir().unwrap();
        let mut a = PendingRequest {
            request_id: "a".into(),
            origin: sample_origin(),
            spec: sample_spec(),
            queued_at_ms: 1_000,
            expires_at_ms: u64::MAX,
            state: RequestState::Pending,
            response: None,
            notified_via: vec![],
            metadata: serde_json::Map::new(),
        };
        let b = PendingRequest {
            request_id: "b".into(),
            origin: sample_origin(),
            spec: sample_spec(),
            queued_at_ms: 2_000,
            expires_at_ms: u64::MAX,
            state: RequestState::Pending,
            response: None,
            notified_via: vec![],
            metadata: serde_json::Map::new(),
        };
        a.queued_at_ms = 2_000;
        a.spec.request_id = Some("a".into());
        crate::inbox::enqueue(tmp.path(), &a).unwrap();
        let mut b = b;
        b.queued_at_ms = 1_000;
        b.spec.request_id = Some("b".into());
        crate::inbox::enqueue(tmp.path(), &b).unwrap();

        let entries = snapshot_inbox(tmp.path()).unwrap();
        assert!(entries.iter().any(|e| e.request_id == "a"));
        assert!(entries.iter().any(|e| e.request_id == "b"));
    }
}
