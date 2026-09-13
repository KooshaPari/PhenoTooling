# Phinbox Inbox-Helper Polish Plan

## Priority 1: Critical Bugs (must fix)

### P1-1: OpenLatest should activate inbox-helper, not browser
- **File**: `crates/phinbox/src/bin_app.rs` lines 139-143
- **Fix**: Replace `open` command with `activate_inbox_helper(port)` call
- **Effort**: 1 line change

### P1-2: Date picker non-functional
- **File**: `DetailView.swift` line 8, 65
- **Fix**: Add `@State private var dateVal = Date()`, bind DatePicker to it, send ISO8601 string on submit
- **Effort**: 5 lines

### P1-3: Support secret field type (password masking)
- **File**: `DetailView.swift` fieldBody switch
- **Fix**: Add `case "secret":` with `SecureField` instead of `TextField`
- **Effort**: 3 lines

### P1-4: Use ButtonSpec from daemon
- **Files**: `Models.swift` (add `buttons` field), `DetailView.swift` (read labels)
- **Fix**: Parse `buttons` from JSON, use `buttons?.confirm` / `buttons?.cancel` for labels, honor `default_is_cancel`
- **Effort**: 15 lines

## Priority 2: Spec Feature Parity

### P2-1: Respect `default` values for all field types
- **Files**: `DetailView.swift` init, `InboxManager.swift`
- **Fix**: When selecting a request, initialize state vars from `field.default` / `notes.default`
- **Effort**: 10 lines

### P2-2: Use `placeholder` from spec
- **File**: `DetailView.swift` fieldInput
- **Fix**: Pass `request.spec.field.placeholder` (need to parse it from the enum variant)
- **Effort**: 5 lines

### P2-3: Enforce `max_length` on text inputs
- **File**: `DetailView.swift` fieldInput
- **Fix**: Add `.maxLength()` modifier or manual truncation
- **Effort**: 5 lines

### P2-4: Enforce `min`/`max` on integer input
- **File**: `DetailView.swift` fieldBody for integer
- **Fix**: Validate Int(value) against min/max before enabling Submit
- **Effort**: 8 lines

### P2-5: Respect `picker_kind` for date fields
- **File**: `DetailView.swift` fieldBody for date_time
- **Fix**: Switch on `picker_kind` to show `.dateOnly` / `.hourAndMinute` / `.composite`
- **Effort**: 5 lines

### P2-6: Honor `default_index` for choice fields
- **File**: `DetailView.swift` init
- **Fix**: Pre-select choice based on `default_index`
- **Effort**: 3 lines

## Priority 3: Performance

### P3-1: Replace 2s polling with DispatchSource file watcher
- **File**: `InboxManager.swift`
- **Fix**: Use `DispatchSource.makeFileSystemObjectSource` on inbox directory for `write` events. Fall back to 5s polling.
- **Effort**: 25 lines
- **Impact**: Near-zero CPU when idle, instant response to new requests

### P3-2: Diff-based refresh
- **File**: `InboxManager.swift`
- **Fix**: Compare loaded request IDs against current; only animate if changed
- **Effort**: 8 lines

### P3-3: Offload file reading from main thread
- **File**: `InboxManager.swift`
- **Fix**: Read files in background Task, publish results on MainActor
- **Effort**: 15 lines

## Priority 4: UX Polish

### P4-1: Keyboard navigation (Cmd+Up/Down)
- **File**: `RootView.swift`
- **Fix**: Add `.onKeyPress` handlers for arrow keys to move selection
- **Effort**: 15 lines

### P4-2: Window state persistence
- **File**: `main.swift`
- **Fix**: Save/restore window frame to UserDefaults
- **Effort**: 10 lines

### P4-3: Timeout countdown indicator
- **File**: `DetailView.swift`
- **Fix**: Show remaining time from `expires_at_ms` with a progress bar or countdown text
- **Effort**: 15 lines

### P4-4: Selectable metadata text
- **File**: `DetailView.swift` headerCard
- **Fix**: Wrap metadata labels in `Text(...).textSelection(.enabled)` (macOS 13+)
- **Effort**: 2 lines

### P4-5: Fallback for unknown field types
- **File**: `DetailView.swift` fieldBody default case
- **Fix**: Show "Unsupported field type: {kind}" with raw JSON dump
- **Effort**: 5 lines

### P4-6: Tray badge update
- **File**: `InboxManager.swift`
- **Fix**: Post notification or call daemon API to update tray badge count
- **Effort**: 10 lines

## Priority 5: Model Cleanup

### P5-1: Replace string-based urgency with typed enum
- **Files**: `Models.swift`, `RowView.swift`, `DetailView.swift`
- **Fix**: Add `Urgency` enum to Models, decode from JSON, pattern match instead of string comparison
- **Effort**: 15 lines

### P5-2: Flatten FieldSpec to match daemon's tagged enum
- **Files**: `Models.swift`, `DetailView.swift`
- **Fix**: Replace flat `FieldSpec` with enum matching daemon's `FieldSpec` variants (Text, LongText, Integer, Choice, Boolean, DateTime)
- **Effort**: 30 lines
- **Impact**: Enables proper access to all per-variant fields (placeholder, default, min, max, secret, etc.)

---

## Execution Order

1. **P1-1** through **P1-4** (critical bugs) — immediate
2. **P5-2** (flatten FieldSpec) — prerequisite for P2-1 through P2-6
3. **P2-1** through **P2-6** (spec parity) — after model cleanup
4. **P3-1** through **P3-3** (performance) — independent, can parallel
5. **P4-1** through **P4-6** (UX polish) — after core fixes

## Estimated Total Effort

- P1 (critical): ~25 lines
- P5 (model): ~45 lines  
- P2 (spec parity): ~36 lines
- P3 (performance): ~48 lines
- P4 (UX polish): ~62 lines
- **Total**: ~216 lines across 7 files
