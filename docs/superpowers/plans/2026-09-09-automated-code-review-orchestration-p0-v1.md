# Automated Code Review Workflow Orchestration — P0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the *non-remote* scaffolding for the fleet-wide automated code-review pipeline: a static provider catalog (SP1) and a lefthook pre-push local gate (SP6). Both are local-only — no GitHub Apps installed, no PATs rotated, no remote mutations.

**Architecture:** Pure data + shell. SP1 is a YAML catalog + JSON Schema + a tiny Python loader that double-validates the file. SP6 is a new pre-push hook in the existing `phenotype-tooling-mergify/templates/lefthook.yml` plus a small shell script. Both live inside `phenotype-tooling-mergify/` so the rest of the pipeline (SP2 router, SP3 triage, SP4 forge, SP5 resolver) can import from one canonical home.

**Tech Stack:** YAML, JSON Schema (Draft 2020-12), Python 3.11+ stdlib (`yaml`, `jsonschema`, `pytest`), Bash, Lefthook 1.6+.

**Spec:** [`docs/superpowers/specs/2026-09-09-automated-code-review-workflow-orchestration-design.md`](../specs/2026-09-09-automated-code-review-workflow-orchestration-design.md)

**Phase scope (from spec §8):**
> **P0**: SP1 catalog + SP6 lefthook extension (no remote) — Reusable scaffolding

---

## File Structure (locked in by this plan)

```
phenotype-tooling-mergify/
├── cr_roster/                              # NEW — SP1 home
│   ├── README.md                           # NEW — usage, schema notes
│   ├── providers.yaml                      # NEW — canonical catalog
│   ├── schema.json                         # NEW — JSON Schema for providers.yaml
│   ├── loader.py                           # NEW — Python loader (validates + returns list[dict])
│   ├── tests/
│   │   ├── __init__.py                     # NEW
│   │   ├── conftest.py                     # NEW — pytest fixtures
│   │   └── test_loader.py                  # NEW — validation + priority tests
│   └── Makefile                            # NEW — `make validate`, `make dump-json`
└── templates/
    ├── lefthook.yml                        # MODIFY — append cr-local-gate pre-push step
    └── lefthook-hooks/
        └── cr-local-gate.sh                # NEW — local pre-CR script

docs/superpowers/
└── plans/
    └── 2026-09-09-automated-code-review-orchestration-p0-v1.md   # THIS FILE
```

Files that change together live together: SP1's data, schema, loader, and tests are siblings in `cr_roster/`. SP6's hook script sits next to the template that references it (`templates/lefthook-hooks/`).

---

## Conventions for all tasks

- **Repo root for every command:** `/Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify` (set with the `cwd` parameter, never with `cd`).
- **Commit message format:** Conventional Commits — enforced by the repo's own `lefthook.yml` `commit-msg` hook.
- **TDD:** for every Python change, write the failing test first (Task N.1 → N.2 red → N.3 green → N.4 commit).
- **Branch:** all work lands on a fresh branch `cr-orchestration/p0-scaffolding` cut from `main`. Single PR at the end.

---

## Task 1: Create the roster branch

**Files:**
- Create: `phenotype-tooling-mergify/.git/refs/heads/cr-orchestration/p0-scaffolding` (auto via `git checkout -b`)

- [ ] **Step 1: Confirm a clean working tree**

Run: `git status --porcelain`
Expected output: empty (no uncommitted changes). If non-empty, stop and surface to operator.

- [ ] **Step 2: Confirm main is up to date**

Run: `git fetch origin && git rev-parse --abbrev-ref HEAD`
Expected: `main` printed.

- [ ] **Step 3: Create and switch to the feature branch**

Run: `git checkout -b cr-orchestration/p0-scaffolding`
Expected: `Switched to a new branch 'cr-orchestration/p0-scaffolding'`.

- [ ] **Step 4: No commit yet — leave the branch empty**

Don't commit. Move to Task 2.

---

## Task 2: Scaffold the `cr_roster/` directory

**Files:**
- Create: `phenotype-tooling-mergify/cr_roster/.gitkeep`
- Create: `phenotype-tooling-mergify/cr_roster/tests/__init__.py`
- Create: `phenotype-tooling-mergify/cr_roster/tests/conftest.py`

- [ ] **Step 1: Create the directory tree**

Run:
```bash
mkdir -p cr_roster/tests
```

- [ ] **Step 2: Add a `.gitkeep` so the empty directory survives an initial commit**

Create `cr_roster/.gitkeep` with this exact content:
```text
# Reserved for SP1 cr_roster artifacts (providers.yaml, schema.json, loader.py, tests/).
# Populated by the P0 implementation plan.
```

- [ ] **Step 3: Create empty `tests/__init__.py`**

Create `cr_roster/tests/__init__.py` with this exact content:
```python
"""Test package for cr_roster."""
```

- [ ] **Step 4: Create `tests/conftest.py` with the roster-path fixture**

Create `cr_roster/tests/conftest.py` with this exact content:
```python
"""Pytest fixtures for cr_roster tests."""
from __future__ import annotations

from pathlib import Path

import pytest

ROSTER_ROOT = Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def roster_root() -> Path:
    """Absolute path to the cr_roster/ directory."""
    return ROSTER_ROOT


@pytest.fixture(scope="session")
def providers_yaml_path(roster_root: Path) -> Path:
    """Absolute path to providers.yaml."""
    return roster_root / "providers.yaml"


@pytest.fixture(scope="session")
def schema_json_path(roster_root: Path) -> Path:
    """Absolute path to schema.json."""
    return roster_root / "schema.json"
```

- [ ] **Step 5: Verify the tree**

Run: `find cr_roster -type f | sort`
Expected output (exact):
```
cr_roster/.gitkeep
cr_roster/tests/__init__.py
cr_roster/tests/conftest.py
```

- [ ] **Step 6: Commit**

Run:
```bash
git add cr_roster/.gitkeep cr_roster/tests/__init__.py cr_roster/tests/conftest.py
git commit -m "chore(cr_roster): scaffold directory and pytest fixtures"
```

Expected: one commit on `cr-orchestration/p0-scaffolding`.

---

## Task 3: Write the failing test for `loader.py`

**Files:**
- Create: `phenotype-tooling-mergify/cr_roster/tests/test_loader.py`

- [ ] **Step 1: Write the failing test**

Create `cr_roster/tests/test_loader.py` with this exact content:
```python
"""Tests for cr_roster.loader."""
from __future__ import annotations

import pytest

from cr_roster.loader import load_providers, RosterError


def test_loader_module_imports():
    """The loader module must import cleanly."""
    # If this test runs, the import succeeded.
    assert load_providers is not None
    assert RosterError is not None


def test_providers_yaml_exists(providers_yaml_path):
    """providers.yaml must exist before load_providers() can succeed."""
    assert providers_yaml_path.exists(), (
        f"Missing providers.yaml at {providers_yaml_path}. "
        "Run Task 4 to create it."
    )


def test_load_providers_returns_nonempty_list(providers_yaml_path):
    """load_providers() must return at least one provider (per spec D3 queue)."""
    if not providers_yaml_path.exists():
        pytest.skip("providers.yaml not yet created (Task 4)")
    providers = load_providers()
    assert isinstance(providers, list)
    assert len(providers) >= 6, (
        f"spec D3 lists 6 providers; got {len(providers)}"
    )


def test_load_providers_priority_is_sequential():
    """Per spec D3, providers must be returned in priority order."""
    providers = load_providers()
    priorities = [p["priority"] for p in providers]
    assert priorities == sorted(priorities), (
        f"priorities must be 1..N in order; got {priorities}"
    )
    assert priorities[0] == 1, "first provider must have priority 1"


def test_load_providers_have_required_fields():
    """Every provider must declare the fields the rest of the pipeline consumes."""
    required = {"id", "name", "priority", "free_tier", "quota_per_day", "endpoint"}
    for p in load_providers():
        missing = required - set(p.keys())
        assert not missing, f"provider {p.get('id')!r} missing fields: {missing}"


def test_load_providers_validate_against_schema():
    """The catalog must satisfy its own JSON Schema."""
    try:
        load_providers(validate_schema=True)
    except RosterError as exc:
        pytest.fail(f"schema validation failed: {exc}")
```

- [ ] **Step 2: Run the tests — expect failures**

Run:
```bash
python3 -m pytest cr_roster/tests/test_loader.py -v
```

Expected: **all 5 tests fail** with `ModuleNotFoundError: No module named 'cr_roster'` or `ImportError`. This is the red phase.

- [ ] **Step 3: Confirm red, do not commit yet**

If any test passes accidentally, something is wrong with the test. Stop and re-read Task 3.

---

## Task 4: Implement `loader.py` (minimal — schema-less first pass)

**Files:**
- Create: `phenotype-tooling-mergify/cr_roster/loader.py`
- Create: `phenotype-tooling-mergify/cr_roster/__init__.py`

- [ ] **Step 1: Create the package marker**

Create `cr_roster/__init__.py` with this exact content:
```python
"""cr_roster: static catalog of code-review providers (SP1)."""
from cr_roster.loader import RosterError, load_providers

__all__ = ["load_providers", "RosterError"]
```

- [ ] **Step 2: Implement the loader (no schema validation yet)**

Create `cr_roster/loader.py` with this exact content:
```python
"""Loader for the cr_roster provider catalog.

Public API:
    load_providers(validate_schema: bool = False) -> list[dict]

Raises:
    RosterError: when the YAML is missing, malformed, or fails schema validation.
"""
from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml

ROSTER_ROOT = Path(__file__).resolve().parent
PROVIDERS_YAML = ROSTER_ROOT / "providers.yaml"
SCHEMA_JSON = ROSTER_ROOT / "schema.json"


class RosterError(Exception):
    """Raised when the roster cannot be loaded or validated."""


def load_providers(validate_schema: bool = False) -> list[dict[str, Any]]:
    """Load and return the provider catalog as a list of dicts.

    Args:
        validate_schema: When True, validate the YAML against schema.json.

    Returns:
        Providers sorted by ascending ``priority`` (1 = highest).

    Raises:
        RosterError: if the file is missing, malformed, or fails validation.
    """
    if not PROVIDERS_YAML.exists():
        raise RosterError(
            f"providers.yaml not found at {PROVIDERS_YAML}. "
            "See docs/superpowers/specs/2026-09-09-automated-code-review-workflow-orchestration-design.md §3 SP1."
        )

    try:
        with PROVIDERS_YAML.open("r", encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        raise RosterError(f"providers.yaml is malformed: {exc}") from exc

    if not isinstance(data, dict) or "providers" not in data:
        raise RosterError(
            "providers.yaml must be a mapping with a top-level 'providers' key"
        )

    providers = data["providers"]
    if not isinstance(providers, list):
        raise RosterError("'providers' must be a list")

    if validate_schema:
        _validate_against_schema(providers)

    providers.sort(key=lambda p: p.get("priority", 10_000))
    return providers


def _validate_against_schema(providers: list[dict[str, Any]]) -> None:
    """Validate the loaded providers against schema.json. Implemented in Task 6."""
    # Placeholder until Task 6 wires jsonschema. Keeping the call site stable
    # avoids touching tests once Task 6 lands.
    return None
```

- [ ] **Step 3: Run the tests — expect test_loader_module_imports and test_providers_yaml_exists to fail (file missing), the rest to skip**

Run:
```bash
python3 -m pytest cr_roster/tests/test_loader.py -v
```

Expected:
- `test_loader_module_imports` PASSES (imports work)
- `test_providers_yaml_exists` FAILS (`providers.yaml` doesn't exist yet)
- `test_load_providers_returns_nonempty_list` SKIPS (`pytest.skip` branch)
- `test_load_providers_priority_is_sequential` FAILS (`RosterError` raised because file missing — accept this for now, it will go green in Task 5)
- `test_load_providers_have_required_fields` FAILS (same reason)
- `test_load_providers_validate_against_schema` FAILS (same reason)

- [ ] **Step 4: Don't commit yet — the next task creates the YAML that the remaining tests need**

---

## Task 5: Author `providers.yaml` with the 6 providers from spec D3

**Files:**
- Create: `phenotype-tooling-mergify/cr_roster/providers.yaml`

- [ ] **Step 1: Create the catalog**

Create `cr_roster/providers.yaml` with this exact content:
```yaml
# cr_roster/providers.yaml — canonical catalog of code-review providers.
#
# Source of truth for spec D3:
#   docs/superpowers/specs/2026-09-09-automated-code-review-workflow-orchestration-design.md §6
#
# Rules:
#   * priority MUST be unique and contiguous starting at 1.
#   * ids MUST be stable; renaming an id is a breaking change for SP2 router state.
#   * free_tier refers to the public free-tier limit as of 2026-09-09. Verify before each release.
#   * endpoint is informational; SP2 router handles auth, not this file.

schema_version: 1

providers:
  - id: coderabbit
    name: CodeRabbit
    priority: 1
    free_tier: "2 free PR reviews/day per public repo; unlimited on OSS"
    quota_per_day: 2
    endpoint: https://api.coderabbit.ai/v1/reviews
    auth: app_installation
    self_hostable: false
    notes: "Default primary per spec D2."

  - id: pr-agent
    name: PR-Agent (CodiumAI)
    priority: 2
    free_tier: "Self-hosted free; managed: 30-day trial"
    quota_per_day: null
    endpoint: https://api.codium.ai/agent
    auth: api_key
    self_hostable: true
    notes: "Open-source; self-host recommended for fleets."

  - id: gemini-code
    name: Gemini Code Assist
    priority: 3
    free_tier: "60 req/min, generous daily cap for personal Gmail accounts"
    quota_per_day: 1500
    endpoint: https://generativelanguage.googleapis.com/v1beta
    auth: api_key
    self_hostable: false
    notes: "Google account required."

  - id: sourcery
    name: Sourcery
    priority: 4
    free_tier: "200 reviews/month"
    quota_per_day: 7
    endpoint: https://sourcery.ai/api/v0
    auth: api_key
    self_hostable: false
    notes: ""

  - id: greptile
    name: Greptile
    priority: 5
    free_tier: "50 PR reviews/month on OSS; paid otherwise"
    quota_per_day: 2
    endpoint: https://api.greptile.com/v2
    auth: api_key
    self_hostable: false
    notes: ""

  - id: bito
    name: Bito
    priority: 6
    free_tier: "30 PR reviews/month"
    quota_per_day: 1
    endpoint: https://api.bito.dev/v1
    auth: api_key
    self_hostable: false
    notes: ""
```

- [ ] **Step 2: Run the loader tests — expect them all green**

Run:
```bash
python3 -m pytest cr_roster/tests/test_loader.py -v
```

Expected: **all 6 tests PASS**.

- [ ] **Step 3: Smoke-test the loader from the CLI**

Run:
```bash
python3 -c "from cr_roster import load_providers; [print(p['priority'], p['id'], p['name']) for p in load_providers()]"
```

Expected output (exact):
```
1 coderabbit CodeRabbit
2 pr-agent PR-Agent (CodiumAI)
3 gemini-code Gemini Code Assist
4 sourcery Sourcery
5 greptile Greptile
6 bito Bito
```

- [ ] **Step 4: Commit**

Run:
```bash
git add cr_roster/__init__.py cr_roster/loader.py cr_roster/providers.yaml
git commit -m "feat(cr_roster): add provider catalog and loader (SP1)"
```

Expected: one commit.

---

## Task 6: Add `schema.json` and wire validation

**Files:**
- Create: `phenotype-tooling-mergify/cr_roster/schema.json`
- Modify: `phenotype-tooling-mergify/cr_roster/loader.py:79-90` (replace placeholder)

- [ ] **Step 1: Create the JSON Schema**

Create `cr_roster/schema.json` with this exact content:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://github.com/KooshaPari/phenotype-tooling/cr_roster/schema.json",
  "title": "cr_roster providers catalog",
  "type": "object",
  "required": ["schema_version", "providers"],
  "additionalProperties": false,
  "properties": {
    "schema_version": {
      "type": "integer",
      "const": 1
    },
    "providers": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": [
          "id",
          "name",
          "priority",
          "free_tier",
          "quota_per_day",
          "endpoint",
          "auth",
          "self_hostable"
        ],
        "additionalProperties": true,
        "properties": {
          "id": {
            "type": "string",
            "pattern": "^[a-z][a-z0-9-]{1,40}$"
          },
          "name": { "type": "string", "minLength": 1 },
          "priority": { "type": "integer", "minimum": 1 },
          "free_tier": { "type": "string", "minLength": 1 },
          "quota_per_day": {
            "anyOf": [
              { "type": "integer", "minimum": 0 },
              { "type": "null" }
            ]
          },
          "endpoint": { "type": "string", "format": "uri" },
          "auth": {
            "type": "string",
            "enum": ["api_key", "app_installation", "oauth", "none"]
          },
          "self_hostable": { "type": "boolean" },
          "notes": { "type": "string" }
        }
      }
    }
  }
}
```

- [ ] **Step 2: Add a failing test for schema enforcement (negative case)**

Append the following test to `cr_roster/tests/test_loader.py` (just before the final blank line):
```python
def test_load_providers_rejects_malformed_entry(tmp_path, monkeypatch):
    """A provider missing the 'endpoint' field must be rejected."""
    bad_yaml = tmp_path / "bad.yaml"
    bad_yaml.write_text(
        "schema_version: 1\n"
        "providers:\n"
        "  - id: bad\n"
        "    name: Bad\n"
        "    priority: 1\n"
        "    free_tier: 'none'\n"
        "    quota_per_day: 0\n"
        "    auth: api_key\n"
        "    self_hostable: false\n"
    )
    monkeypatch.setattr("cr_roster.loader.PROVIDERS_YAML", bad_yaml)
    with pytest.raises(RosterError):
        load_providers(validate_schema=True)
```

- [ ] **Step 3: Run the negative test — expect it to fail (schema validation not wired yet)**

Run:
```bash
python3 -m pytest cr_roster/tests/test_loader.py::test_load_providers_rejects_malformed_entry -v
```

Expected: FAIL with `RosterError: ... 'endpoint' is a required property` once Step 4 lands. Before Step 4 the test should fail with no schema-validation error (because `_validate_against_schema` is a no-op). Both are acceptable reds — the goal is **after Step 4**, the test passes.

- [ ] **Step 4: Wire real JSON-Schema validation in `loader.py`**

In `cr_roster/loader.py`, replace the placeholder `_validate_against_schema` function:

OLD:
```python
def _validate_against_schema(providers: list[dict[str, Any]]) -> None:
    """Validate the loaded providers against schema.json. Implemented in Task 6."""
    # Placeholder until Task 6 wires jsonschema. Keeping the call site stable
    # avoids touching tests once Task 6 lands.
    return None
```

NEW:
```python
def _validate_against_schema(providers: list[dict[str, Any]]) -> None:
    """Validate the loaded providers against schema.json."""
    if not SCHEMA_JSON.exists():
        raise RosterError(
            f"schema.json not found at {SCHEMA_JSON}; cannot validate."
        )
    try:
        import jsonschema  # local import so the dep is optional for non-validating callers
    except ImportError as exc:
        raise RosterError(
            "jsonschema is not installed; install with `pip install jsonschema`"
        ) from exc

    with SCHEMA_JSON.open("r", encoding="utf-8") as fh:
        schema = json.load(fh)

    validator = jsonschema.Draft202012Validator(schema)
    errors = sorted(validator.iter_errors({"schema_version": 1, "providers": providers}), key=lambda e: e.path)
    if errors:
        msgs = [f"{'/'.join(map(str, e.path)) or '<root>'}: {e.message}" for e in errors]
        raise RosterError("schema validation failed:\n  - " + "\n  - ".join(msgs))
```

- [ ] **Step 5: Add the missing `json` import to `loader.py`**

At the top of `cr_roster/loader.py`, modify the import block:

OLD:
```python
import yaml
```

NEW:
```python
import json

import yaml
```

- [ ] **Step 6: Run the full test suite — expect all 7 tests green**

Run:
```bash
python3 -m pytest cr_roster/tests/test_loader.py -v
```

Expected: **all 7 tests PASS**.

- [ ] **Step 7: Commit**

Run:
```bash
git add cr_roster/schema.json cr_roster/loader.py cr_roster/tests/test_loader.py
git commit -m "feat(cr_roster): add JSON Schema validation (SP1 hardening)"
```

Expected: one commit.

---

## Task 7: Add a `Makefile` for local dev

**Files:**
- Create: `phenotype-tooling-mergify/cr_roster/Makefile`

- [ ] **Step 1: Create the Makefile**

Create `cr_roster/Makefile` with this exact content:
```makefile
# cr_roster local dev helpers.
# Usage: `make -C cr_roster <target>`

PYTHON ?= python3

.PHONY: validate dump-json test clean help

help:
	@echo "Targets:"
	@echo "  validate   Run loader with schema validation enabled"
	@echo "  dump-json  Print providers as JSON to stdout"
	@echo "  test       Run pytest"
	@echo "  clean      Remove __pycache__"

validate:
	$(PYTHON) -c "from cr_roster import load_providers; load_providers(validate_schema=True); print('OK')"

dump-json:
	$(PYTHON) -c "import json; from cr_roster import load_providers; print(json.dumps(load_providers(), indent=2))"

test:
	$(PYTHON) -m pytest tests/ -v

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
```

- [ ] **Step 2: Verify `make validate` works**

Run: `make -C cr_roster validate`
Expected output: `OK`.

- [ ] **Step 3: Verify `make dump-json` works**

Run: `make -C cr_roster dump-json | head -20`
Expected: JSON array starting with the coderabbit entry, 6 entries total.

- [ ] **Step 4: Verify `make test` works**

Run: `make -C cr_roster test`
Expected: `7 passed`.

- [ ] **Step 5: Commit**

Run:
```bash
git add cr_roster/Makefile
git commit -m "chore(cr_roster): add Makefile for local dev"
```

Expected: one commit.

---

## Task 8: Document SP1 in a README

**Files:**
- Create: `phenotype-tooling-mergify/cr_roster/README.md`

- [ ] **Step 1: Create the README**

Create `cr_roster/README.md` with this exact content:
```markdown
# cr_roster

Static catalog of code-review (CR) providers used by the
[automated code-review orchestration pipeline](../../docs/superpowers/specs/2026-09-09-automated-code-review-workflow-orchestration-design.md)
(SP1).

## Files

| File             | Purpose                                                |
| ---------------- | ------------------------------------------------------ |
| `providers.yaml` | Canonical catalog — one entry per provider.            |
| `schema.json`    | JSON Schema (Draft 2020-12) for `providers.yaml`.      |
| `loader.py`      | Python API: `load_providers(validate_schema=False)`.   |
| `tests/`         | Pytest suite for the loader and the catalog.           |
| `Makefile`       | `make validate`, `make dump-json`, `make test`.        |

## Adding a provider

1. Append an entry to `providers.yaml`. Use the next contiguous priority.
2. Run `make validate` to confirm the schema passes.
3. Run `make test`.
4. Open a PR with a Conventional Commits message, e.g.
   `feat(cr_roster): add <provider-id> as priority N`.

## Renaming a provider id

`id` changes are **breaking** — SP2 router (Phase P1) keys its daily-quota
state on it. Coordinate the rename with the router rollout.

## Consumed by

- SP2 router (`cr-router`, Go binary) — `make dump-json` produces the JSON
  the router will embed.
- SP3 triage, SP4 forge (Python scripts) — `from cr_roster import load_providers`.
```

- [ ] **Step 2: Commit**

Run:
```bash
git add cr_roster/README.md
git commit -m "docs(cr_roster): add README"
```

Expected: one commit.

---

## Task 9: Add a `cr-local-gate` hook script

**Files:**
- Create: `phenotype-tooling-mergify/templates/lefthook-hooks/cr-local-gate.sh`

- [ ] **Step 1: Create the hook script**

Create `templates/lefthook-hooks/cr-local-gate.sh` with this exact content:
```bash
#!/usr/bin/env bash
# cr-local-gate.sh — local pre-push code-review-style sanity check (SP6).
#
# Purpose: catch the obvious stuff (formatting drift, oversized files, secret
# patterns, missing tests on changed code) BEFORE a remote CR provider is
# invoked. This is NOT a substitute for CodeRabbit/PR-Agent — it's a fast
# local filter that reduces wasted remote tokens.
#
# Exit codes:
#   0 = pass (gate green)
#   1 = fail (push blocked)
#
# Environment overrides:
#   CR_LOCAL_GATE=0  → skip the gate entirely
#   CR_LOCAL_GATE_STRICT=1 → promote warnings to failures
#
# This script is called from the cr-local-gate lefthook pre-push command
# defined in templates/lefthook.yml.

set -euo pipefail

if [[ "${CR_LOCAL_GATE:-1}" == "0" ]]; then
  echo "cr-local-gate: skipped (CR_LOCAL_GATE=0)"
  exit 0
fi

STRICT="${CR_LOCAL_GATE_STRICT:-0}"
WARN_ONLY=0
FAIL=0
REPO_ROOT="$(git rev-parse --show-toplevel)"
CHANGED="$(git diff --name-only --diff-filter=ACM @{push} 2>/dev/null \
  || git diff --name-only --diff-filter=ACM HEAD~1..HEAD 2>/dev/null \
  || echo "")"

note() { printf '  • %s\n' "$*"; }
warn() { printf '  ⚠ %s\n' "$*"; WARN_ONLY=1; }
err()  { printf '  ✗ %s\n' "$*" >&2; FAIL=1; }

echo "cr-local-gate: checking $REPO_ROOT"

# 1. No files larger than 5 MB.
while IFS= read -r f; do
  [[ -z "$f" || ! -f "$REPO_ROOT/$f" ]] && continue
  size=$(wc -c < "$REPO_ROOT/$f" | tr -d ' ')
  if (( size > 5242880 )); then
    err "$f is ${size} bytes (>5 MB); shrink or move to release artifacts"
  fi
done <<< "${CHANGED:-}"

# 2. No .only / .skip / FIXME markers in changed test/code files.
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    *.ts|*.tsx|*.js|*.jsx|*.py|*.rs|*.go) ;;
    *) continue ;;
  esac
  if grep -nE '\.(only|skip)\(|FIXME|XXX' "$REPO_ROOT/$f" >/dev/null 2>&1; then
    warn "$f contains .only/.skip/FIXME/XXX markers"
  fi
done <<< "${CHANGED:-}"

# 3. Crash-style prints left in production paths.
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    *.ts|*.tsx|*.js|*.jsx) ;;
    *) continue ;;
  esac
  if grep -nE 'console\.log\(|debugger;|TODO\(' "$REPO_ROOT/$f" >/dev/null 2>&1; then
    warn "$f contains console.log/debugger/TODO( — review before push"
  fi
done <<< "${CHANGED:-}"

# 4. CR-roster sanity: confirm the providers catalog is parseable when present.
ROSTER="$REPO_ROOT/cr_roster/providers.yaml"
if [[ -f "$ROSTER" ]]; then
  if ! python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$ROSTER" >/dev/null 2>&1; then
    err "cr_roster/providers.yaml is not parseable YAML"
  else
    note "cr_roster/providers.yaml: OK"
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
echo "cr-local-gate: pass"
exit 0
```

- [ ] **Step 2: Make the script executable**

Run:
```bash
chmod +x templates/lefthook-hooks/cr-local-gate.sh
ls -l templates/lefthook-hooks/cr-local-gate.sh
```

Expected: `-rwxr-xr-x` permissions shown.

- [ ] **Step 3: Smoke-test: skip path**

Run:
```bash
CR_LOCAL_GATE=0 bash templates/lefthook-hooks/cr-local-gate.sh
```

Expected output: `cr-local-gate: skipped (CR_LOCAL_GATE=0)` and exit code `0`.

- [ ] **Step 4: Smoke-test: clean working tree**

Run:
```bash
bash templates/lefthook-hooks/cr-local-gate.sh
```

Expected output: ends with `cr-local-gate: pass`, exit code `0`.

- [ ] **Step 5: Smoke-test: synthetic oversized file**

Run:
```bash
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/sub"
dd if=/dev/zero of="$TMPDIR/sub/huge.bin" bs=1024 count=6000 status=none
cd "$TMPDIR" && git init -q && git add . && git -c user.email=t@t -c user.name=t commit -q -m init
echo change > sub/huge.bin
bash <repo>/templates/lefthook-hooks/cr-local-gate.sh 2>&1 | tail -5 || true
rm -rf "$TMPDIR"
```

Expected: non-zero exit and `cr-local-gate: FAIL` printed. If 0, the file filter is broken — stop and re-check.

> Note: substitute `<repo>` with the absolute path to `phenotype-tooling-mergify/`.

- [ ] **Step 6: Don't commit yet — next task wires it into the template**

---

## Task 10: Wire the hook into `templates/lefthook.yml`

**Files:**
- Modify: `phenotype-tooling-mergify/templates/lefthook.yml:10-18` (changelog header)
- Modify: `phenotype-tooling-mergify/templates/lefthook.yml:189-223` (pre-push block — add new command)

- [ ] **Step 1: Update the template changelog header**

In `templates/lefthook.yml`, replace the existing changelog block (lines 10–18) with the following extended version. Locate the existing block by its distinctive `Changes from v1 (2026-06-11):` text.

OLD:
```yaml
# Changes from v1 (2026-06-11):
#   + conventional commit message validation (commit-msg hook)
#   + pre-commit now runs `just fmt --check` for stacks that have a fmt recipe
#   + pre-push now runs cargo-deny (Rust) and npm/pnpm audit (Node)
#   + file-size check (warn on files > 1 MB, fail on > 5 MB)
#   + yaml/json/toml validation
#   + secret scanning via trufflehog on pre-commit
#   + private `do_not_edit` block at the bottom shows the canonical
#     minimal config (consumers can copy that block to override everything)
```

NEW:
```yaml
# Changes from v1 (2026-06-11):
#   + conventional commit message validation (commit-msg hook)
#   + pre-commit now runs `just fmt --check` for stacks that have a fmt recipe
#   + pre-push now runs cargo-deny (Rust) and npm/pnpm audit (Node)
#   + file-size check (warn on files > 1 MB, fail on > 5 MB)
#   + yaml/json/toml validation
#   + secret scanning via trufflehog on pre-commit
#   + private `do_not_edit` block at the bottom shows the canonical
#     minimal config (consumers can copy that block to override everything)
#
# Changes from v2 (2026-06-14) for the SP6 cr-local-gate rollout:
#   + new pre-push command `cr-local-gate` invokes
#     templates/lefthook-hooks/cr-local-gate.sh
#   + cr-local-gate is a fast local-only CR-style check; bypass with
#     CR_LOCAL_GATE=0; promote warnings to failures with
#     CR_LOCAL_GATE_STRICT=1
#   + see spec §3 SP6 and §6 D8 (local lefthook stage = pre-push)
```

- [ ] **Step 2: Add the `cr-local-gate` command to the `pre-push` block**

Locate the `pre-push:` block (begins at line 189). Insert a new command **after** the existing `npm-audit` command and **before** the `# ── post-checkout (best-effort)` comment. The patch point is the line `# ── post-checkout (best-effort)`.

OLD (the marker line that comes right after the pre-push block):
```yaml
# ── post-checkout (best-effort) ─────────────────────────────────────────────
```

NEW:
```yaml
    cr-local-gate:
      tags: [gate, slow, cr]
      run: |
        # Local pre-CR sanity check (spec SP6). Invokes a small shell script
        # that catches the obvious stuff before any remote CR token is burned.
        # Skip with CR_LOCAL_GATE=0; promote warnings with CR_LOCAL_GATE_STRICT=1.
        if [ -f "$LEFTHOOK_CONFIG_DIR/../templates/lefthook-hooks/cr-local-gate.sh" ]; then
          bash "$LEFTHOOK_CONFIG_DIR/../templates/lefthook-hooks/cr-local-gate.sh"
        else
          SCRIPT="$(dirname "$(git rev-parse --git-dir)")/../templates/lefthook-hooks/cr-local-gate.sh"
          if [ -f "$SCRIPT" ]; then bash "$SCRIPT"; else echo "cr-local-gate: script not found; skipping"; fi
        fi
      skip:
        - rebase

# ── post-checkout (best-effort) ─────────────────────────────────────────────
```

- [ ] **Step 3: Verify the YAML still parses**

Run:
```bash
python3 -c "import yaml; yaml.safe_load(open('templates/lefthook.yml')); print('OK')"
```

Expected: `OK`.

- [ ] **Step 4: Commit**

Run:
```bash
git add templates/lefthook.yml templates/lefthook-hooks/cr-local-gate.sh
git commit -m "feat(lefthook): add cr-local-gate pre-push hook (SP6)"
```

Expected: one commit.

---

## Task 11: Verify the hook fires inside a real consumer repo

**Files:** none modified. Verification only.

- [ ] **Step 1: Pick a fleet consumer and install the new template**

Use `phenotype-fleet-ops/` as the consumer (it already has a lefthook.yml and references the template). Run:
```bash
cd phenotype-fleet-ops
lefthook install
```

Expected: lefthook installs hooks; `.git/hooks/pre-push` now exists and is executable.

- [ ] **Step 2: Confirm the cr-local-gate line landed**

Run:
```bash
lefthook run pre-push --commands cr-local-gate --force
```

Expected output ends with `cr-local-gate: pass` and exit code `0`.

- [ ] **Step 3: Skip-path sanity**

Run:
```bash
CR_LOCAL_GATE=0 lefthook run pre-push --commands cr-local-gate --force
```

Expected output: `cr-local-gate: skipped (CR_LOCAL_GATE=0)` and exit code `0`.

- [ ] **Step 4: Don't commit consumer changes — just verify**

`phenotype-fleet-ops/lefthook.yml` was not modified by this plan. If it needs to inherit the new pre-push step, that is **P5 work** (fleet-wide template publish), out of scope for P0.

- [ ] **Step 5: Pop back to the feature branch root**

Run:
```bash
git checkout cr-orchestration/p0-scaffolding
```

Expected: returns to the feature branch.

---

## Task 12: Final P0 verification

**Files:** none modified.

- [ ] **Step 1: Run the full test suite once more**

Run:
```bash
make -C cr_roster test
```

Expected: `7 passed`.

- [ ] **Step 2: Validate the catalog**

Run:
```bash
make -C cr_roster validate
```

Expected: `OK`.

- [ ] **Step 3: Confirm git history**

Run:
```bash
git log --oneline main..HEAD
```

Expected output: between 6 and 10 commits, each Conventional Commits formatted, touching only:
- `cr_roster/` (SP1)
- `templates/lefthook.yml` (SP6)
- `templates/lefthook-hooks/cr-local-gate.sh` (SP6)

No other paths.

- [ ] **Step 4: Confirm no remote push happened**

Run:
```bash
git log --oneline origin/main..HEAD 2>/dev/null | wc -l
```

Expected: `0` (zero — we did not push). If non-zero, stop and surface to operator; pushing is destructive.

- [ ] **Step 5: Append an audit log entry**

Run:
```bash
cat >> ~/.forge/audit/sessions.log <<'EOF'
[2026-09-09] P0 implementation complete on branch cr-orchestration/p0-scaffolding in phenotype-tooling-mergify. SP1 (cr_roster) + SP6 (lefthook cr-local-gate) shipped. 7 pytest tests green. No remote push performed. Awaiting operator PR review before P1 (SP2 router).
EOF
echo "logged"
```

Expected: `logged` printed.

---

## Self-Review

**1. Spec coverage** (skimmed against `docs/superpowers/specs/2026-09-09-automated-code-review-workflow-orchestration-design.md`):

| Spec item | Plan task |
| --- | --- |
| §3 SP1 catalog | Tasks 2–8 |
| §3 SP6 lefthook pre-push hook | Tasks 9–11 |
| §6 D2 default primary = CodeRabbit | Task 5 (providers.yaml priority 1) |
| §6 D3 provider queue order | Task 5 (sequential priorities 1–6) |
| §6 D4 quota_per_day field | Task 5 (per-provider value) |
| §6 D8 local lefthook stage = pre-push | Task 10 (placement) |
| §6 D9 first-run repo = phenotype-tooling-mergify | Task 1 (branch lives there) |
| §7 assumption: `auto-cr-resolve` label unused | Not in P0; deferred to P3 (issue-forge) |
| §10 DoD: no remote mutations, no irreversible defaults | Task 12 Step 4 explicit check |

All §6 decisions relevant to P0 are addressed. Decisions relevant only to later phases (D5 ignored-comment threshold → P2, D6 auto-merge → P4, D10 notification → P3) are correctly deferred.

**2. Placeholder scan** — searched the plan for `TBD`, `TODO`, `???`, `XXX`, `FIXME`, "appropriate error handling", "similar to Task N". Result: zero matches inside plan steps. The only `TODO(` and `FIXME` strings appear inside the **cr-local-gate.sh source code as regex patterns** the gate looks for (Task 9, lines that grep for `FIXME|XXX` and `TODO\(`) — these are intentional and documented in code comments.

**3. Type consistency** — every reference to `load_providers`, `RosterError`, `PROVIDERS_YAML`, `SCHEMA_JSON`, `CR_LOCAL_GATE`, and `CR_LOCAL_GATE_STRICT` matches across Tasks 3–12. Field names `id`, `priority`, `free_tier`, `quota_per_day`, `endpoint`, `auth`, `self_hostable`, `notes`, `schema_version` are consistent between `providers.yaml`, `schema.json`, and `test_loader.py`.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-09-09-automated-code-review-orchestration-p0-v1.md`.**

Two execution options:

1. **Subagent-Driven (recommended)** — Dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — Execute tasks in this session using `executing-plans`, batch execution with checkpoints for review.

**Note for the operator:** Per `AGENTS.md` and the brainstorming-skill gate, this plan is non-destructive (no remote push, no GitHub App install, no PAT rotation). When you're back, you can:
- Reply **"approved"** and I'll open the PR for `cr-orchestration/p0-scaffolding` → `main` in `phenotype-tooling-mergify`.
- Reply **"execute inline"** and I'll run the tasks in this session with checkpoints.
- Reply **"execute via subagents"** and I'll dispatch per task.
- Reply with edits and I'll patch the plan first.
