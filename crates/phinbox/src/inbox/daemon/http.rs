//! HTTP server loop and request handling for the inbox daemon.
//!
//! This module contains the blocking HTTP server that serves the inbox
//! UI on `http://127.0.0.1:7117/inbox/<id>`. It's deliberately minimal:
//! one thread per connection, no async runtime, no TLS — the inbox is
//! local-only and binds to `127.0.0.1` only.

use std::io::{BufRead, BufReader, Read, Write};
use std::net::TcpStream;
use std::path::Path;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;

use crate::inbox::{list_pending, load, PendingRequest, RequestState};
use tracing::warn;

use super::lockfile::LOCKFILE_NAME;

/// How long an idle HTTP connection is allowed to live.
const HTTP_KEEPALIVE_TIMEOUT: Duration = Duration::from_secs(30);

/// Get the mtime of a file in seconds since UNIX epoch.
pub(crate) fn mtime_sec(path: &Path) -> Option<u64> {
    std::fs::metadata(path)
        .ok()
        .and_then(|m| m.modified().ok())
        .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
        .map(|d| d.as_secs())
}

/// Run the HTTP accept loop. Returns when `shutdown` is set.
pub(crate) fn run_http_loop(
    listener: std::net::TcpListener,
    inbox_root: &Path,
    shutdown: &Arc<AtomicBool>,
) -> std::io::Result<()> {
    let mut shutdown_mtime = mtime_sec(&inbox_root.join(LOCKFILE_NAME));
    loop {
        if shutdown.load(Ordering::SeqCst) {
            break;
        }
        // Wake up early if the lockfile was touched by `stop()`.
        let current_mtime = mtime_sec(&inbox_root.join(LOCKFILE_NAME));
        if current_mtime != shutdown_mtime {
            shutdown_mtime = current_mtime;
            if shutdown.load(Ordering::SeqCst) {
                break;
            }
        }

        match listener.accept() {
            Ok((stream, _)) => {
                let inbox_root = inbox_root.to_path_buf();
                let shutdown = Arc::clone(shutdown);
                thread::spawn(move || {
                    let _ = handle_connection(stream, &inbox_root, &shutdown);
                });
            }
            Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                // Non-blocking + no incoming connection; check shutdown
                // flag at a reasonable cadence (50ms ≈ 20 Hz).
                thread::sleep(Duration::from_millis(50));
            }
            Err(e) => {
                warn!(error = %e, "accept failed");
                thread::sleep(Duration::from_millis(50));
            }
        }
    }
    Ok(())
}

/// Handle a single HTTP connection.
fn handle_connection(
    mut stream: TcpStream,
    inbox_root: &Path,
    shutdown: &Arc<AtomicBool>,
) -> std::io::Result<()> {
    stream.set_read_timeout(Some(HTTP_KEEPALIVE_TIMEOUT))?;
    stream.set_write_timeout(Some(Duration::from_secs(5)))?;

    let mut reader = BufReader::new(stream.try_clone()?);
    let mut request_line = String::new();
    if reader.read_line(&mut request_line)? == 0 {
        return Ok(());
    }
    let mut headers = Vec::new();
    loop {
        let mut line = String::new();
        let n = reader.read_line(&mut line)?;
        if n == 0 || line == "\r\n" {
            break;
        }
        headers.push(line);
    }

    let mut parts = request_line.split_whitespace();
    let method = parts.next().unwrap_or("");
    let target = parts.next().unwrap_or("");
    let _version = parts.next().unwrap_or("");

    let (route, id) = parse_route(target);

    let body = match route {
        Route::Health => Some(simple_text(200, "ok")),
        Route::Index => Some(text_response(
            200,
            &crate::views::render_inbox_index_html(
                &list_pending(inbox_root).unwrap_or_default(),
            ),
        )),
        Route::InboxForm => match id.and_then(|id| load(inbox_root, &id).ok()) {
            Some(req) if matches!(req.state, RequestState::Expired) => {
                Some(text_response(
                    200,
                    &crate::views::render_expired_html(&req),
                ))
            }
            Some(req) => Some(text_response(200, &render_inbox_html(&req))),
            None => Some(simple_text(404, "request not found")),
        },
        Route::Answer => {
            let id = match id {
                Some(id) => id,
                None => {
                    return write_response(
                        &mut stream,
                        400,
                        "Bad Request",
                        "text/plain; charset=utf-8",
                        b"missing id",
                    )
                }
            };
            if method == "GET" {
                // Re-render the form so a user who navigates back / lands
                // here directly sees the same submission UI.
                match load(inbox_root, &id) {
                    Ok(req) if matches!(req.state, RequestState::Expired) => {
                        Some(text_response(
                            200,
                            &crate::views::render_expired_html(&req),
                        ))
                    }
                    Ok(req) => Some(text_response(200, &render_inbox_html(&req))),
                    Err(_) => Some(simple_text(404, "request not found")),
                }
            } else if method != "POST" {
                return write_response(
                    &mut stream,
                    405,
                    "Method Not Allowed",
                    "text/plain; charset=utf-8",
                    b"",
                );
            } else {
                // Read body.
                let content_length = headers
                    .iter()
                    .find_map(|h| {
                        let (k, v) = h.split_once(':')?;
                        if k.eq_ignore_ascii_case("content-length") {
                            v.trim().parse::<usize>().ok()
                        } else {
                            None
                        }
                    })
                    .unwrap_or(0);
                let mut buf = vec![0u8; content_length];
                if content_length > 0 {
                    reader.read_exact(&mut buf)?;
                }
                // Reject answers for expired requests.
                match load(inbox_root, &id) {
                    Ok(req) if matches!(req.state, RequestState::Expired) => {
                        Some(text_response(
                            410,
                            &format!(
                                "<h1>Request Expired</h1>\
                                 <p>This request expired and can no longer be answered.</p>\
                                 <a href=/inbox>Return to inbox</a>"
                            ),
                        ))
                    }
                    _ => match super::form::submit_answer(inbox_root, &id, &buf) {
                        Ok(_) => redirect_response(&mut stream, &format!("/inbox/{}/done", id))?,
                        Err(e) => Some(text_response(400, &format!("<h1>Error</h1><p>{e}</p>"))),
                    },
                }
            }
        }
        Route::Done => match id.and_then(|id| load(inbox_root, &id).ok()) {
            Some(req) => {
                let html = crate::views::render_answer_html(
                    &req.request_id,
                    matches!(req.state, RequestState::Answered),
                    if matches!(req.state, RequestState::Answered) {
                        "Your answer was recorded."
                    } else {
                        "Request cancelled."
                    },
                );
                Some(text_response(200, &html))
            }
            None => Some(simple_text(404, "request not found")),
        },
        Route::Static(p) => match p.as_str() {
            "" | "index.css" | "index.html" => return write_response(
                &mut stream,
                200,
                "OK",
                "text/css; charset=utf-8",
                render_inbox_css().as_bytes(),
            ),
            other if other.ends_with(".css") => return write_response(
                &mut stream,
                200,
                "OK",
                "text/css; charset=utf-8",
                render_inbox_css().as_bytes(),
            ),
            other => {
                let body = format!("not found: {other}");
                return write_response(
                    &mut stream,
                    404,
                    "Not Found",
                    "text/plain; charset=utf-8",
                    body.as_bytes(),
                );
            }
        },
        Route::NotFound => Some(simple_text(404, "not found")),
        Route::Shutdown => {
            if method == "POST" {
                shutdown.store(true, Ordering::SeqCst);
                Some(simple_text(200, "shutting down"))
            } else {
                Some(simple_text(403, "use POST"))
            }
        }
    };

    let body = body.unwrap_or_else(|| simple_text(500, "internal"));
    write_response(
        &mut stream,
        200,
        "OK",
        "text/html; charset=utf-8",
        body.as_bytes(),
    )?;
    Ok(())
}

// ---- Routing ----

#[derive(Debug, PartialEq, Eq)]
pub(crate) enum Route {
    Health,
    Index,
    InboxForm,
    Answer,
    Done,
    Static(String),
    NotFound,
    Shutdown,
}

pub(crate) fn parse_route(target: &str) -> (Route, Option<String>) {
    let path = target.split('?').next().unwrap_or(target).trim_end_matches('/');
    if path == "/health" || path == "/ping" {
        return (Route::Health, None);
    }
    if path == "/shutdown" {
        return (Route::Shutdown, None);
    }
    if path.is_empty() {
        return (Route::Index, None);
    }
    if path == "/inbox" {
        return (Route::Index, None);
    }
    if let Some(rest) = path.strip_prefix("/inbox/") {
        // /inbox/{rid}/answer  → submit answer (POST) or re-render form (GET)
        // /inbox/{rid}/done   → post-submit confirmation page
        // /inbox/{rid}        → form detail
        if let Some(rid) = rest.strip_suffix("/answer") {
            return (Route::Answer, Some(rid.to_string()));
        }
        if let Some(rid) = rest.strip_suffix("/done") {
            return (Route::Done, Some(rid.to_string()));
        }
        return (Route::InboxForm, Some(rest.to_string()));
    }
    if let Some(rest) = path.strip_prefix("/answer/") {
        return (Route::Answer, Some(rest.to_string()));
    }
    if let Some(rest) = path.strip_prefix("/static/") {
        return (Route::Static(rest.to_string()), None);
    }
    (Route::NotFound, None)
}

// ---- HTTP response helpers ----

fn write_response(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    content_type: &str,
    body: &[u8],
) -> std::io::Result<()> {
    write!(
        stream,
        "HTTP/1.1 {status} {reason}\r\nContent-Length: {}\r\nConnection: close\r\nContent-Type: {content_type}\r\n\r\n",
        body.len()
    )?;
    stream.write_all(body)?;
    stream.flush()?;
    Ok(())
}

/// Write a 302 redirect to `location` and return `None` so the caller
/// doesn't accidentally fall through to the default 200 path.
pub(crate) fn redirect_response(
    stream: &mut TcpStream,
    location: &str,
) -> std::io::Result<Option<String>> {
    let body = format!(
        "<!doctype html><meta charset=utf-8><title>redirecting</title>\
         <body><p>Redirecting to <a href=\"{loc}\">{loc}</a>…</p>",
        loc = location
    );
    write!(
        stream,
        "HTTP/1.1 302 Found\r\nLocation: {loc}\r\nContent-Length: {}\r\nConnection: close\r\nContent-Type: text/html; charset=utf-8\r\n\r\n",
        body.len(),
        loc = location
    )?;
    stream.write_all(body.as_bytes())?;
    stream.flush()?;
    Ok(None)
}

fn simple_text(status: u16, msg: &str) -> String {
    let _ = status;
    format!(
        "<!doctype html><meta charset=utf-8><title>phinbox</title><body style=\"font-family:system-ui;margin:2rem\"><h1>phinbox</h1><p>{msg}</p>"
    )
}

fn text_response(status: u16, body: &str) -> String {
    let _ = status;
    body.to_string()
}

// ---- HTML rendering for the daemon's own form pages ----

fn render_inbox_html(req: &PendingRequest) -> String {
    use crate::views::render_form_html;
    let body = render_form_html(req);
    let title = html_escape(&req.spec.title);
    let question = html_escape(&req.spec.question);
    format!(
        "<!doctype html><meta charset=utf-8><title>{title}</title>\
         <style>{css}</style><body>\
         <div class=card>\
           <h1>{title}</h1><p class=q>{question}</p>\
           <p class=meta>From <code>{origin}</code> on <code>{host}</code> · queued {queued}</p>\
           {body}\
         </div>",
        title = title,
        css = render_inbox_css(),
        question = question,
        origin = html_escape(&req.origin.process),
        host = html_escape(&req.origin.hostname),
        queued = format_relative_time(req.queued_at_ms),
        body = body,
    )
}

fn render_inbox_css() -> &'static str {
    "body{background:#0f172a;color:#f8fafc;font-family:system-ui;margin:0;padding:2rem}.card{max-width:640px;margin:auto;background:#1e293b;border-radius:12px;padding:2rem;box-shadow:0 8px 24px rgba(0,0,0,.4)}h1{margin:0 0 .5rem}p.q{white-space:pre-wrap;color:#cbd5e1}p.meta{color:#64748b;font-size:.85rem;margin:0 0 1.5rem}label{display:block;margin:1rem 0 .25rem;font-weight:600}input[type=text],input[type=number],textarea,select{width:100%;padding:.6rem;border-radius:8px;background:#0f172a;color:#f8fafc;border:1px solid #334155;font-size:1rem}textarea{min-height:6rem}button{padding:.7rem 1.4rem;border-radius:8px;border:none;font-weight:600;cursor:pointer;margin-right:.5rem}.ok{background:#22c55e;color:#052e16}.cancel{background:#ef4444;color:#fff}.secret{background:#facc15;color:#1c1917}"
}

pub(crate) fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

pub(crate) fn format_relative_time(ms: u64) -> String {
    let now = crate::inbox::unix_now_ms();
    let delta = now.saturating_sub(ms);
    if delta < 60_000 {
        return format!("{delta}s ago");
    }
    if delta < 3_600_000 {
        return format!("{}m ago", delta / 60_000);
    }
    if delta < 86_400_000 {
        return format!("{}h ago", delta / 3_600_000);
    }
    format!("{}d ago", delta / 86_400_000)
}
