#!/usr/bin/env bash
# cr-local-gate.sh — local pre-push code-review-style sanity check (SP6).
#
# Purpose: catch the obvious stuff (formatting drift, oversized files, debug
# markers, an unusable code-review provider roster) BEFORE a remote CR provider
# is invoked. This is NOT a substitute for CodeRabbit/PR-Agent — it's a fast
# local filter that reduces wasted remote tokens.
#
# Terminal states / exit codes:
#   SKIPPED → 0  (gate disabled via CR_LOCAL_GATE=0, or nothing changed)
#   PASS    → 0  (all checks green; warnings may have been printed)
#   FAIL    → 1  (a hard error, or a warning promoted by strict mode)
#
# Environment overrides:
#   CR_LOCAL_GATE=0         → skip the gate entirely (SKIPPED)
#   CR_LOCAL_GATE_STRICT=1  → promote warnings (incl. RosterError) to failures
#   CR_LOCAL_GATE_PYTHON    → interpreter used for the cr_roster checks
#
# Roster contract:
#   * parse/schema/roster-content problems (unparseable YAML, missing required
#     primary provider) are hard errors → FAIL
#   * RosterError from a plain (schema-less) load is a warning → PASS unless
#     CR_LOCAL_GATE_STRICT=1
#
# This script is called from the cr-local-gate lefthook pre-push command
# defined in templates/lefthook.yml.

set -euo pipefail

if [[ "${CR_LOCAL_GATE:-1}" == "0" ]]; then
  echo "cr-local-gate: SKIPPED (CR_LOCAL_GATE=0)"
  exit 0
fi

STRICT="${CR_LOCAL_GATE_STRICT:-0}"
WARN_ONLY=0
FAIL=0
REPO_ROOT="$(git rev-parse --show-toplevel)"

# Required primary code-review provider (spec D2). Absence blocks the push.
REQUIRED_PROVIDER="coderabbit"

note() { printf '  • %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; WARN_ONLY=1; }
err()  { printf '  x %s\n' "$*" >&2; FAIL=1; }

# --- changed-file detection -------------------------------------------------
# Prefer the push range when an upstream exists (real pre-push run); otherwise
# fall back to the working tree vs HEAD (local invocation / no tracking branch).
detect_changed() {
  if git rev-parse --abbrev-ref '@{push}' >/dev/null 2>&1; then
    git diff --name-only --diff-filter=ACM '@{push}' 2>/dev/null || true
  else
    git diff --name-only --diff-filter=ACM HEAD 2>/dev/null || true
  fi
}

CHANGED="$(detect_changed)"

if [[ -z "${CHANGED//[[:space:]]/}" ]]; then
  echo "cr-local-gate: SKIPPED (no changed files)"
  exit 0
fi

echo "cr-local-gate: checking $REPO_ROOT"

# 1. No files larger than 5 MB.
while IFS= read -r f; do
  [[ -z "$f" || ! -f "$REPO_ROOT/$f" ]] && continue
  size=$(wc -c < "$REPO_ROOT/$f" | tr -d ' ')
  if (( size > 5242880 )); then
    err "$f is ${size} bytes (>5 MB); shrink or move to release artifacts"
  fi
done <<< "$CHANGED"

# 2. No .only / .skip / FIXME markers in changed test/code files.
while IFS= read -r f; do
  [[ -z "$f" || ! -f "$REPO_ROOT/$f" ]] && continue
  case "$f" in
    *.ts|*.tsx|*.js|*.jsx|*.py|*.rs|*.go) ;;
    *) continue ;;
  esac
  if grep -nE '\.(only|skip)\(|FIXME|XXX' "$REPO_ROOT/$f" >/dev/null 2>&1; then
    warn "$f contains .only/.skip/FIXME/XXX markers"
  fi
done <<< "$CHANGED"

# 3. Crash-style prints left in production paths.
while IFS= read -r f; do
  [[ -z "$f" || ! -f "$REPO_ROOT/$f" ]] && continue
  case "$f" in
    *.ts|*.tsx|*.js|*.jsx) ;;
    *) continue ;;
  esac
  if grep -nE 'console\.log\(|debugger;|TODO\(' "$REPO_ROOT/$f" >/dev/null 2>&1; then
    warn "$f contains console.log/debugger/TODO( — review before push"
  fi
done <<< "$CHANGED"

# 4. CR-roster sanity: the providers catalog must load and carry the primary.
ROSTER="$REPO_ROOT/cr_roster/providers.yaml"
if [[ -f "$ROSTER" ]]; then
  PYBIN="${CR_LOCAL_GATE_PYTHON:-python3}"
  if ! command -v "$PYBIN" >/dev/null 2>&1; then
    warn "cr_roster: interpreter '$PYBIN' not found; roster check skipped"
  elif ! PYTHONPATH="$REPO_ROOT" "$PYBIN" -c 'import yaml' >/dev/null 2>&1; then
    warn "cr_roster: PyYAML unavailable for '$PYBIN'; roster check skipped"
  else
    set +e
    ROSTER_OUT="$(PYTHONPATH="$REPO_ROOT" CR_REQUIRED_PROVIDER="$REQUIRED_PROVIDER" \
      "$PYBIN" - <<'PY' 2>&1
import os
import sys

# Exit codes consumed by cr-local-gate.sh:
#   0 = roster OK
#   3 = soft roster problem (catalog absent -> "tier only", not a blocker)
#   4 = hard roster problem (unparseable/misshaped catalog, unimportable
#       module, or missing required primary provider)
try:
    from cr_roster import load_providers, RosterError
except Exception as exc:  # noqa: BLE001 - report and let the shell decide
    print(f"cr_roster import failed: {exc}")
    sys.exit(4)

required = os.environ.get("CR_REQUIRED_PROVIDER", "coderabbit")

try:
    providers = load_providers()
except RosterError as exc:
    print(f"RosterError: {exc}")
    # A catalog that simply is not there is a soft signal ("tier only");
    # a catalog that exists but is unparseable/misshaped is a hard error.
    sys.exit(3 if "not found" in str(exc) else 4)

ids = [p.get("id") for p in providers]
if required not in ids:
    print(
        f"required primary provider '{required}' missing from cr_roster/providers.yaml "
        f"(found: {', '.join(str(i) for i in ids) or 'none'})"
    )
    sys.exit(4)

print(f"cr_roster/providers.yaml: OK ({len(providers)} providers, primary '{required}' present)")
sys.exit(0)
PY
)"
    ROSTER_RC=$?
    set -e
    case "$ROSTER_RC" in
      0) note "$ROSTER_OUT" ;;
      3) warn "cr_roster: $ROSTER_OUT" ;;
      *) err "cr_roster: $ROSTER_OUT" ;;
    esac
  fi
fi

if (( FAIL )); then
  echo "cr-local-gate: FAIL" >&2
  exit 1
fi
if (( WARN_ONLY )) && [[ "$STRICT" == "1" ]]; then
  echo "cr-local-gate: FAIL (warnings promoted to errors by CR_LOCAL_GATE_STRICT=1)" >&2
  exit 1
fi
echo "cr-local-gate: PASS"
exit 0
