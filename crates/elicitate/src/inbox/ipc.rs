//! JSON-RPC 2.0 over a local Unix domain socket.
//!
//! This is the multi-process IPC layer for `elicitate`. The daemon binds a
//! socket under the inbox root; clients (Swift app, CLI, other agents) connect,
//! write one JSON-RPC request per line, and read responses line-by-line.
//!
//! Framing: every message is a single JSON object terminated by `\n`. No
//! `Content-Length` headers, no SSE, no websockets — line-delimited JSON-RPC,
//! which is exactly what stdio LSP-style clients also use (we just swap stdio
//! for a UDS).
//!
//! Lifecycle:
//! - The daemon creates the socket path and listens with `tokio::net::UnixListener`.
//! - Each connection is read on a dedicated task; messages are dispatched via
//!   a single shared `RpcState` locked by a `parking_lot::Mutex`.
//! - The socket is unlinked on shutdown.
//!
//! Methods:
//! - `daemon.ping`               → `Pong { now_ms, version }`
//! - `daemon.shutdown`           → `{ ok: true }`, then daemon stops
//! - `inbox.list`                → `{ requests: [PendingRequest] }`
//! - `inbox.get`     (`rid`)     → `{ request: PendingRequest }` or not-found
//! - `inbox.answer`   (`rid`, `response`) → `{ request: PendingRequest }` after finalization
//! - `inbox.cancel`   (`rid`)    → `{ request: PendingRequest }` (writes Cancelled response)
//! - `inbox.subscribe`           → server-streaming: emits `{ kind: "added|answered|removed", request? }`
//!                                until the client closes the connection.
//!
//! Errors follow JSON-RPC 2.0: `{ code, message, data? }` with negative integers
//! reserved for protocol errors and a positive range for app errors.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;

use parking_lot::Mutex;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{UnixListener, UnixStream};
use tokio::sync::{broadcast, Notify};
use tokio::task::JoinHandle;

use crate::error::ElicitError;
use crate::inbox::{
    self, list_pending, load_pending, load_request, PendingRequest, RequestState,
    ResponseStatus, ELICITATE_VERSION,
};
use crate::spec::ElicitResponse;

// ---------------------------------------------------------------------------
// Socket path
// ---------------------------------------------------------------------------

/// Returns the canonical IPC socket path for a given inbox root.
pub fn ipc_socket_path(root: &Path) -> PathBuf {
    root.join("ipc.sock")
}

/// Best-effort: read the lockfile in `root` and return the IPC socket path.
/// Returns `None` if the lockfile is missing, malformed, or `ipc_sock` is empty
/// (older daemons predating IPC).
pub fn live_socket(root: &Path) -> Option<PathBuf> {
    let payload = crate::inbox::daemon::lockfile::read_lockfile(root)?;
    let sock = payload.ipc_sock?;
    if sock.as_os_str().is_empty() {
        return None;
    }
    Some(sock)
}

// ---------------------------------------------------------------------------
// JSON-RPC envelope
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Request {
    pub jsonrpc: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub id: Option<Value>,
    pub method: String,
    #[serde(default)]
    pub params: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Response {
    pub jsonrpc: String,
    pub id: Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub result: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<RpcError>,
}

impl Response {
    fn ok(id: Value, result: Value) -> Self {
        Self {
            jsonrpc: "2.0".into(),
            id,
            result: Some(result),
            error: None,
        }
    }

    fn err(id: Value, code: i32, message: impl Into<String>) -> Self {
        Self {
            jsonrpc: "2.0".into(),
            id,
            result: None,
            error: Some(RpcError {
                code,
                message: message.into(),
                data: None,
            }),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RpcError {
    pub code: i32,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<Value>,
}

// JSON-RPC 2.0 standard error codes (negative = protocol, positive = app).
pub const ERR_PARSE: i32 = -32700;
pub const ERR_INVALID_REQUEST: i32 = -32600;
pub const ERR_METHOD_NOT_FOUND: i32 = -32601;
pub const ERR_INVALID_PARAMS: i32 = -32602;
pub const ERR_INTERNAL: i32 = -32603;

// App-level error codes (1xxx range).
pub const ERR_NOT_FOUND: i32 = 1001;
pub const ERR_BAD_STATE: i32 = 1002;
pub const ERR_IO: i32 = 1003;

// ---------------------------------------------------------------------------
// Method params
// ---------------------------------------------------------------------------

#[derive(Debug, Default, Deserialize)]
pub struct AnswerParams {
    pub rid: String,
    pub response: ElicitResponse,
}

#[derive(Debug, Default, Deserialize)]
pub struct RidParams {
    pub rid: String,
}

// ---------------------------------------------------------------------------
// Server state (shared with the daemon)
// ---------------------------------------------------------------------------

/// Shared state the IPC server needs.
///
/// Cheap to clone: every field is either a path/Arc or already inside a Mutex.
/// Cloning is how we hand the state to each connection task.
#[derive(Clone)]
pub struct RpcState {
    pub root: PathBuf,
    pub sock_path: PathBuf,
    pub started_ms: i64,
    pub shutdown: Arc<Notify>,
    /// Broadcast channel for inbox change events; size 64 is plenty for a
    /// local multi-client scenario.
    pub changes: broadcast::Sender<ChangeEvent>,
    /// We hold the listener inside an `Arc<Mutex<Option<_>>>` so the daemon
    /// can stop the listener on shutdown. The Option type keeps the listener
    /// inside an async-only type while still letting sync code (the daemon
    /// starter) set up the path before the listener is bound.
    pub listener_slot: Arc<Mutex<Option<UnixListener>>>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum ChangeEvent {
    Added {
        request: PendingRequest,
    },
    Answered {
        rid: String,
        status: ResponseStatus,
    },
    Removed {
        rid: String,
    },
}

impl RpcState {
    pub fn new(root: PathBuf, sock_path: PathBuf) -> Self {
        let (tx, _rx) = broadcast::channel(64);
        Self {
            root,
            sock_path,
            started_ms: inbox::unix_now_ms() as i64,
            shutdown: Arc::new(Notify::new()),
            changes: tx,
            listener_slot: Arc::new(Mutex::new(None)),
        }
    }

    pub fn notify_added(&self, req: &PendingRequest) {
        let _ = self.changes.send(ChangeEvent::Added { request: req.clone() });
    }

    pub fn notify_answered(&self, rid: &str, status: ResponseStatus) {
        let _ = self.changes.send(ChangeEvent::Answered {
            rid: rid.to_string(),
            status,
        });
    }
}

// ---------------------------------------------------------------------------
// Server lifecycle
// ---------------------------------------------------------------------------

/// Bind a Unix listener at `sock_path`, replace any stale socket file, and
/// store the listener inside `state.listener_slot` so callers can drive
/// shutdown.
pub async fn bind_listener(sock_path: &Path) -> Result<UnixListener, ElicitError> {
    if let Some(parent) = sock_path.parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    // Stale socket from a crashed daemon: remove and rebind.
    if sock_path.exists() {
        let _ = std::fs::remove_file(sock_path);
    }
    let listener = UnixListener::bind(sock_path).map_err(|e| {
        ElicitError::Io(std::io::Error::new(
            e.kind(),
            format!("bind ipc socket {}: {e}", sock_path.display()),
        ))
    })?;
    Ok(listener)
}

/// Spawn the accept loop. Returns a join handle; the daemon drops or aborts
/// it during shutdown. Each connection is its own task.
pub fn spawn_accept(state: RpcState, listener: UnixListener) -> JoinHandle<()> {
    tokio::spawn(async move {
        loop {
            tokio::select! {
                _ = state.shutdown.notified() => break,
                accepted = listener.accept() => {
                    match accepted {
                        Ok((stream, _addr)) => {
                            let st = state.clone();
                            tokio::spawn(async move {
                                if let Err(e) = handle_conn(st, stream).await {
                                    tracing::debug!("ipc conn closed: {e}");
                                }
                            });
                        }
                        Err(e) => {
                            tracing::debug!("ipc accept error: {e}");
                            tokio::time::sleep(Duration::from_millis(50)).await;
                        }
                    }
                }
            }
        }
    })
}

async fn handle_conn(state: RpcState, stream: UnixStream) -> std::io::Result<()> {
    let (read_half, mut write_half) = stream.into_split();
    let mut reader = BufReader::new(read_half);
    let mut line = String::new();

    loop {
        line.clear();
        let n = reader.read_line(&mut line).await?;
        if n == 0 {
            return Ok(());
        }
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        // Notifications (no id) vs calls.
        let parsed: Result<Request, _> = serde_json::from_str(trimmed);
        let req = match parsed {
            Ok(r) => r,
            Err(e) => {
                // Parse error → response with id=null per JSON-RPC 2.0.
                let resp = Response::err(Value::Null, ERR_PARSE, e.to_string());
                write_frame(&mut write_half, &resp).await?;
                continue;
            }
        };

        // `inbox.subscribe` is the only long-lived method on a single connection.
        if req.method == "inbox.subscribe" {
            return handle_subscribe(state, &req, &mut write_half).await;
        }

        let id = req.id.clone().unwrap_or(Value::Null);
        let resp = dispatch(&state, req).await;
        write_frame(&mut write_half, &resp_to_envelope(resp, id)).await?;
    }
}

fn resp_to_envelope(r: Response, fallback_id: Value) -> Response {
    // dispatch() always returns a Response with id = Value::Null (we want the
    // server to fill in the id from the request). Normalize here.
    let mut r = r;
    if r.id.is_null() {
        r.id = fallback_id;
    }
    r
}

async fn write_frame<W: AsyncWriteExt + Unpin>(w: &mut W, resp: &Response) -> std::io::Result<()> {
    let s = serde_json::to_string(resp)
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
    w.write_all(s.as_bytes()).await?;
    w.write_all(b"\n").await?;
    w.flush().await
}

// ---------------------------------------------------------------------------
// Method dispatch
// ---------------------------------------------------------------------------

async fn dispatch(state: &RpcState, req: Request) -> Response {
    let id = req.id.clone().unwrap_or(Value::Null);
    match req.method.as_str() {
        "daemon.ping" => Response::ok(
            id,
            json!({
                "now_ms": inbox::unix_now_ms(),
                "started_ms": state.started_ms,
                "version": ELICITATE_VERSION,
                "sock": state.sock_path.to_string_lossy(),
            }),
        ),

        "daemon.shutdown" => {
            state.shutdown.notify_waiters();
            Response::ok(id, json!({ "ok": true }))
        }

        "inbox.list" => match list_pending(&state.root) {
            Ok(reqs) => Response::ok(id, json!({ "requests": reqs })),
            Err(e) => Response::err(id, ERR_IO, e.to_string()),
        },

        "inbox.get" => match parse_params::<RidParams>(&req.params) {
            Ok(p) => match load_request(&state.root, &p.rid) {
                Ok(Some(r)) => Response::ok(id, json!({ "request": r })),
                Ok(None) => Response::err(id, ERR_NOT_FOUND, format!("rid={}", p.rid)),
                Err(e) => Response::err(id, ERR_IO, e.to_string()),
            },
            Err(e) => Response::err(id, ERR_INVALID_PARAMS, e.to_string()),
        },

        "inbox.answer" => match parse_params::<AnswerParams>(&req.params) {
            Ok(p) => match finalize_via_state(state, &p.rid, p.response).await {
                Ok(updated) => Response::ok(id, json!({ "request": updated })),
                Err(e) => e,
            },
            Err(e) => Response::err(id, ERR_INVALID_PARAMS, e.to_string()),
        },

        "inbox.cancel" => match parse_params::<RidParams>(&req.params) {
            Ok(p) => match finalize_via_state(state, &p.rid, ElicitResponse::Cancelled { notes: None }).await {
                Ok(updated) => Response::ok(id, json!({ "request": updated })),
                Err(e) => e,
            },
            Err(e) => Response::err(id, ERR_INVALID_PARAMS, e.to_string()),
        },

        _ => Response::err(id, ERR_METHOD_NOT_FOUND, req.method.clone()),
    }
}

fn parse_params<T: for<'de> Deserialize<'de>>(params: &Value) -> Result<T, String> {
    if params.is_null() {
        // Allow empty params for methods with all-default fields.
        return serde_json::from_value(Value::Object(Default::default()))
            .map_err(|e| e.to_string());
    }
    serde_json::from_value(params.clone()).map_err(|e| e.to_string())
}

/// Finalize a request with the given response, using the same write path as
/// the HTTP form handler. Surfaces a structured error on state mismatch.
async fn finalize_via_state(
    state: &RpcState,
    rid: &str,
    response: ElicitResponse,
) -> Result<PendingRequest, Response> {
    let mut pending = match load_pending(&state.root, rid) {
        Ok(Some(p)) => p,
        Ok(None) => return Err(Response::err(Value::Null, ERR_NOT_FOUND, format!("rid={rid}"))),
        Err(e) => return Err(Response::err(Value::Null, ERR_IO, e.to_string())),
    };
    if !matches!(pending.state, RequestState::Pending) {
        return Err(Response::err(
            Value::Null,
            ERR_BAD_STATE,
            format!("rid={rid} already finalized (state={:?})", pending.state),
        ));
    }
    // Determine new state from the response.
    let new_state = match &response {
        ElicitResponse::Cancelled { .. } => RequestState::Cancelled,
        ElicitResponse::TimedOut { .. } => RequestState::Expired,
        ElicitResponse::Failed { .. } => RequestState::Expired,
        ElicitResponse::Answered { .. } => RequestState::Answered,
    };
    pending.state = new_state;
    pending.response = Some(response);
    match crate::inbox::finalize(&state.root, &pending) {
        Ok(_path) => {
            let status = match &pending.response {
                Some(ElicitResponse::Cancelled { .. }) => ResponseStatus::Cancelled,
                Some(ElicitResponse::TimedOut { .. }) => ResponseStatus::TimedOut,
                Some(_) => ResponseStatus::Answered,
                None => ResponseStatus::Pending,
            };
            state.notify_answered(rid, status);
            Ok(pending)
        }
        Err(e) => Err(Response::err(Value::Null, ERR_IO, e.to_string())),
    }
}

// ---------------------------------------------------------------------------
// Subscribe (server-streaming via line-delimited JSON)
// ---------------------------------------------------------------------------

async fn handle_subscribe<W: AsyncWriteExt + Unpin>(
    state: RpcState,
    req: &Request,
    w: &mut W,
) -> std::io::Result<()> {
    let id = req.id.clone().unwrap_or(Value::Null);

    // Send an initial snapshot (pending + recently answered).
    let pending = list_pending(&state.root).unwrap_or_default();
    let snapshot = json!({
        "jsonrpc": "2.0",
        "id": id,
        "result": {
            "kind": "snapshot",
            "requests": pending,
        }
    });
    write_frame(w, &serde_json::from_value::<Response>(snapshot).unwrap_or_else(|_| {
        Response::ok(id.clone(), json!({ "kind": "snapshot", "requests": pending }))
    }))
    .await?;

    let mut rx = state.changes.subscribe();
    loop {
        tokio::select! {
            _ = state.shutdown.notified() => return Ok(()),
            evt = rx.recv() => match evt {
                Ok(change) => {
                    let payload = serde_json::to_value(&change).unwrap_or(Value::Null);
                    let resp = Response::ok(id.clone(), payload);
                    write_frame(w, &resp).await?;
                }
                Err(broadcast::error::RecvError::Lagged(_)) => continue,
                Err(broadcast::error::RecvError::Closed) => return Ok(()),
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Sync client (used by the CLI)
// ---------------------------------------------------------------------------

/// A small blocking client used by the CLI subcommands. Each call opens a new
/// socket connection — the daemon's accept loop is already concurrent and the
/// latency on UDS is microseconds, so connection reuse isn't worth the
/// complexity for human-driven CLI use.
pub struct Client {
    sock: PathBuf,
}

impl Client {
    pub fn connect_to(sock: PathBuf) -> Result<Self, ElicitError> {
        if !sock.exists() {
            return Err(ElicitError::Io(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                format!("ipc socket not found at {}", sock.display()),
            )));
        }
        Ok(Self { sock })
    }

    /// Convenience constructor that walks the inbox root + lockfile.
    pub fn connect_default() -> Result<Self, ElicitError> {
        let root = inbox::default_inbox_root();
        let sock = live_socket(&root)
            .ok_or_else(|| ElicitError::Io(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                "no live elicitate daemon (no lockfile with ipc_sock)",
            )))?;
        Self::connect_to(sock)
    }

    pub fn call(&self, method: &str, params: Value) -> Result<Value, ElicitError> {
        let req = Request {
            jsonrpc: "2.0".into(),
            id: Some(json!(monotonic_id())),
            method: method.to_string(),
            params,
        };
        let line = serde_json::to_string(&req).map_err(ElicitError::Json)?;
        let mut s = std::os::unix::net::UnixStream::connect(&self.sock).map_err(|e| {
            ElicitError::Io(std::io::Error::new(
                e.kind(),
                format!("connect ipc {}: {e}", self.sock.display()),
            ))
        })?;
        use std::io::Write;
        s.write_all(line.as_bytes()).map_err(ElicitError::Io)?;
        s.write_all(b"\n").map_err(ElicitError::Io)?;
        let mut reader = std::io::BufReader::new(s);
        let mut buf = String::new();
        use std::io::BufRead;
        reader.read_line(&mut buf).map_err(ElicitError::Io)?;
        let resp: Response = serde_json::from_str(buf.trim()).map_err(ElicitError::Json)?;
        if let Some(err) = resp.error {
            return Err(ElicitError::Rpc {
                code: err.code,
                message: err.message,
            });
        }
        Ok(resp.result.unwrap_or(Value::Null))
    }
}

fn monotonic_id() -> u64 {
    use std::sync::atomic::{AtomicU64, Ordering};
    static CTR: AtomicU64 = AtomicU64::new(1);
    CTR.fetch_add(1, Ordering::Relaxed)
}

// ---------------------------------------------------------------------------
// Helpers exported for daemon.rs
// ---------------------------------------------------------------------------

/// Serialize a `RpcState`'s key facts for inclusion in the lockfile.
pub fn state_summary(state: &RpcState) -> HashMap<&'static str, String> {
    let mut m = HashMap::new();
    m.insert("sock_path", state.sock_path.to_string_lossy().to_string());
    m.insert("started_ms", state.started_ms.to_string());
    m
}
