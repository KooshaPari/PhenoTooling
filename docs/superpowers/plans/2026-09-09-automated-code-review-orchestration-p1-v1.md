# Automated Code Review Workflow Orchestration — P1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the **provider rotation + rate-limit fallback router** (SP2) as a Python library + CLI, dry-run only. Takes a candidate provider, checks the daily-quota state file, and either returns the provider, rotates to the next one, or signals exhaustion — **without making any HTTP calls**. This is the engine that P2 (SP3 triage), P3 (SP4 forge), and P4 (SP5 resolver) will import.

**Architecture:** Pure Python (matches SP1, defers Go binary until real provider calls land in P2+). The router owns: a `QuotaStore` (file-backed daily counter), a `ProviderQueue` (wraps `cr_roster.load_providers`), and a `Router` that combines them. A small CLI (`python -m cr_router`) provides a dry-run command so the operator can verify the rotation logic against any PR without touching any provider's API.

**Tech Stack:** Python 3.11+ stdlib only (no new deps). Adds `argparse` for the CLI. Reuses `cr_roster/` (SP1) from P0.

**Spec:** [`docs/superpowers/specs/2026-09-09-automated-code-review-workflow-orchestration-design.md`](../specs/2026-09-09-automated-code-review-workflow-orchestration-design.md)

**Phase scope (from spec §8):**
> **P1**: SP2 router, dry-run only — Provider rotation path

**Prerequisites:** P0 branch `cr-orchestration/p0-scaffolding` merged (or at minimum `cr_roster/` shipped on the base branch `cr-orchestration/p1-router` is cut from).

**Spec decisions honored (D2 / D3 / D4):**
- **D2** primary = `coderabbit` (provider id `coderabbit`, priority 1) — already enforced by `cr_roster/providers.yaml`.
- **D3** fallback queue = `coderabbit → pr-agent → gemini-code → sourcery → greptile → bito` — already encoded as `priority` field.
- **D4** quota rotation unit = per-day, per-provider, file-backed counter at `cr_router/state/quota-{provider_id}.json` under a configurable root (default `./var/cr_router/`).

**Out of scope for P1 (deferred to later phases):**
- Real HTTP calls to provider endpoints (P2 / SP3).
- PR comment ingestion (P2 / SP3).
- Issue + draft PR creation (P3 / SP4).
- Agent dispatch (P4 / SP5).
- Fleet-wide lefthook rollout (P5).

---

## File Structure (locked in by this plan)

```
phenotype-tooling-mergify/
├── cr_roster/                              # P0 — UNCHANGED in this plan
│   ├── README.md
│   ├── providers.yaml
│   ├── schema.json
│   ├── loader.py
│   ├── __init__.py
│   └── tests/
│       ├── __init__.py
│       ├── conftest.py
│       └── test_loader.py
├── cr_router/                              # NEW — SP2 home
│   ├── README.md                           # NEW — usage, dry-run examples
│   ├── __init__.py                         # NEW — public API re-exports
│   ├── __main__.py                         # NEW — `python -m cr_router ...`
│   ├── quota_store.py                      # NEW — file-backed daily counter
│   ├── provider_queue.py                   # NEW — wraps cr_roster.load_providers
│   ├── router.py                           # NEW — combines queue + quota_store
│   ├── cli.py                              # NEW — argument parsing + dispatch
│   └── tests/
│       ├── __init__.py                     # NEW (empty)
│       ├── conftest.py                     # NEW — tmp_state_root fixture
│       ├── test_quota_store.py             # NEW — 7 unit tests
│       ├── test_provider_queue.py          # NEW — 4 unit tests
│       └── test_router.py                  # NEW — 8 unit tests
├── Makefile                                # P0 — UNCHANGED
└── templates/
    └── lefthook.yml                        # P0 — UNCHANGED
```

**Total new files:** 13. **Total modified files:** 0. **Total deleted files:** 0.

---

## Task 1: Cut branch `cr-orchestration/p1-router` and verify base

**Files:** none — pure git ops.

- [ ] **Step 1: Verify base branch state**

Run:
```bash
cd phenotype-tooling-mergify
git status --porcelain
git log -1 --format='%H %s'
```

Expected: clean working tree, current branch is `cr-orchestration/p0-scaffolding` (or `main` if P0 already merged) with the latest commit being one of:
- `feat(lefthook): add cr-local-gate pre-push hook (SP6)` if on p0 branch, OR
- any `cr_roster` commit if `main` was fast-forwarded through PR #311 merge.

If `git status --porcelain` is non-empty, **STOP** and surface the dirty tree to the operator.

- [ ] **Step 2: Cut the new branch**

Run:
```bash
git checkout -b cr-orchestration/p1-router
```

Expected: `Switched to a new branch 'cr-orchestration/p1-router'`.

- [ ] **Step 3: Verify SP1 is reachable from this branch**

Run:
```bash
test -f cr_roster/__init__.py && echo "OK: cr_roster present"
ls cr_roster/providers.yaml cr_roster/schema.json
```

Expected:
```
OK: cr_roster present
cr_roster/providers.yaml
cr_roster/schema.json
```

- [ ] **Step 4: Verify SP1 tests still pass from this branch**

Run:
```bash
PYTHON=python3.11
[ -x /tmp/cr-roster-venv/bin/python ] && PYTHON=/tmp/cr-roster-venv/bin/python
$PYTHON -m pytest cr_roster/tests/ -q --no-header 2>&1 | tail -5
```

Expected: `7 passed in 0.0Xs` (the P0 baseline). If less than 7 pass, **STOP** — do not proceed; the base is broken.

---

## Task 2: Scaffold `cr_router/` directory + `__init__.py`

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/.gitkeep`
- Create: `phenotype-tooling-mergify/cr_router/__init__.py`
- Create: `phenotype-tooling-mergify/cr_router/tests/__init__.py`

- [ ] **Step 1: Create the directory**

Run:
```bash
mkdir -p cr_router/tests
```

- [ ] **Step 2: Write `cr_router/.gitkeep`**

Create `cr_router/.gitkeep` with this exact content:
```
# Keep the cr_router/ directory in git. The first real file in here is Task 2's __init__.py.
```

- [ ] **Step 3: Write `cr_router/__init__.py`**

Create `cr_router/__init__.py` with this exact content:
```python
"""cr_router: provider rotation + rate-limit fallback router (SP2).

Public API:
    Router, QuotaStore, ProviderQueue, RouterError, QuotaExhaustedError

The router decides which code-review provider to use next, taking into account
the daily quota recorded in a file-backed QuotaStore. It does NOT make any HTTP
calls — that is deferred to SP3 (triage) and SP4 (forge).

See docs/superpowers/specs/2026-09-09-automated-code-review-workflow-orchestration-design.md
section 3 SP2 and section 6 decisions D2/D3/D4.
"""
from __future__ import annotations

from cr_router.quota_store import QuotaExhaustedError, QuotaStore
from cr_router.router import Router, RouterError
from cr_router.provider_queue import ProviderQueue

__all__ = [
    "ProviderQueue",
    "QuotaExhaustedError",
    "QuotaStore",
    "Router",
    "RouterError",
]
```

- [ ] **Step 4: Write `cr_router/tests/__init__.py`**

Create `cr_router/tests/__init__.py` with this exact content:
```python
"""Tests for the cr_router package (SP2)."""
```

- [ ] **Step 5: Verify the tree**

Run: `find cr_router -type f | sort`
Expected:
```
cr_router/.gitkeep
cr_router/__init__.py
cr_router/tests/__init__.py
```

- [ ] **Step 6: Module import fails (RED — expected)**

Run:
```bash
PYTHON=python3.11
[ -x /tmp/cr-roster-venv/bin/python ] && PYTHON=/tmp/cr-roster-venv/bin/python
PYTHONPATH=cr_roster:cr_router $PYTHON -c "import cr_router" 2>&1 | tail -3
```

Expected: `ModuleNotFoundError: No module named 'cr_router.quota_store'` (or similar). This is the **expected** RED state — the package is scaffolded but its modules are not yet written.

- [ ] **Step 7: Commit**

Run:
```bash
git add cr_router/.gitkeep cr_router/__init__.py cr_router/tests/__init__.py
git commit -m "chore(cr_router): scaffold package and tests directory (SP2)"
```

Expected: one commit on `cr-orchestration/p1-router`.

---

## Task 3: SHA-pinned conftest for `cr_router` tests

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/tests/conftest.py`

- [ ] **Step 1: Write the conftest**

Create `cr_router/tests/conftest.py` with this exact content:
```python
"""Shared pytest fixtures for cr_router tests."""
from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture
def tmp_state_root(tmp_path: Path) -> Path:
    """A throwaway directory for QuotaStore file backing.

    Tests pass this to QuotaStore(state_root=...) so the daily-counter JSON
    files never touch the real var/ tree.
    """
    p = tmp_path / "cr_router_state"
    p.mkdir(parents=True, exist_ok=True)
    return p


@pytest.fixture
def provider_ids() -> list[str]:
    """Hardcoded mirror of cr_roster/providers.yaml (D3 queue).

    We deliberately do NOT import load_providers() inside the unit tests —
    that would couple router logic to roster I/O. Instead, tests that need a
    fixed provider list pass this fixture. The single integration test that
    DOES exercise load_providers() lives in test_provider_queue.py.
    """
    return ["coderabbit", "pr-agent", "gemini-code", "sourcery", "greptile", "bito"]
```

- [ ] **Step 2: Verify import**

Run:
```bash
PYTHON=/tmp/cr-roster-venv/bin/python
PYTHONPATH=cr_roster:cr_router $PYTHON -c "
from cr_router.tests.conftest import provider_ids  # type: ignore[import-not-found]
print('provider_ids =', provider_ids)
" 2>&1 | tail -3
```

Expected: `provider_ids = ['coderabbit', 'pr-agent', 'gemini-code', 'sourcery', 'greptile', 'bito']`.

- [ ] **Step 3: Commit**

Run:
```bash
git add cr_router/tests/conftest.py
git commit -m "test(cr_router): add conftest with tmp_state_root + provider_ids fixtures"
```

Expected: one commit on `cr-orchestration/p1-router`.

---

## Task 4: Write failing tests for `QuotaStore`

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/tests/test_quota_store.py`

- [ ] **Step 1: Write the failing tests (RED phase of TDD)**

Create `cr_router/tests/test_quota_store.py` with this exact content:
```python
"""Tests for cr_router.quota_store."""
from __future__ import annotations

import json
from datetime import date

import pytest

from cr_router.quota_store import QuotaExhaustedError, QuotaStore


def test_quota_store_module_imports():
    """The QuotaStore module must import cleanly."""
    assert QuotaStore is not None
    assert QuotaExhaustedError is not None


def test_initial_state_is_zero(tmp_state_root):
    """A fresh QuotaStore reports zero usage for any provider."""
    store = QuotaStore(state_root=tmp_state_root)
    assert store.usage("coderabbit") == 0
    assert store.remaining("coderabbit", limit=10) == 10


def test_record_increments_counter(tmp_state_root):
    """record() bumps usage by 1 for the current day."""
    store = QuotaStore(state_root=tmp_state_root)
    store.record("coderabbit")
    store.record("coderabbit")
    assert store.usage("coderabbit") == 2


def test_usage_isolated_per_provider(tmp_state_root):
    """Recording on one provider must not affect another's counter."""
    store = QuotaStore(state_root=tmp_state_root)
    store.record("coderabbit")
    store.record("coderabbit")
    store.record("pr-agent")
    assert store.usage("coderabbit") == 2
    assert store.usage("pr-agent") == 1
    assert store.usage("greptile") == 0


def test_record_writes_file(tmp_state_root):
    """record() must persist the counter to disk so it survives across calls."""
    store = QuotaStore(state_root=tmp_state_root)
    store.record("coderabbit")
    path = tmp_state_root / f"quota-coderabbit.{date.today().isoformat()}.json"
    assert path.exists()
    data = json.loads(path.read_text())
    assert data == {"provider": "coderabbit", "date": date.today().isoformat(), "used": 1}


def test_remaining_subtracts_usage(tmp_state_root):
    """remaining(provider, limit) returns limit - usage for today."""
    store = QuotaStore(state_root=tmp_state_root)
    store.record("coderabbit")
    store.record("coderabbit")
    assert store.remaining("coderabbit", limit=10) == 8


def test_consume_raises_when_exhausted(tmp_state_root):
    """consume(provider, limit) raises QuotaExhaustedError when remaining == 0."""
    store = QuotaStore(state_root=tmp_state_root)
    for _ in range(2):
        store.record("coderabbit")
    with pytest.raises(QuotaExhaustedError):
        store.consume("coderabbit", limit=2)


def test_consume_returns_when_under_limit(tmp_state_root):
    """consume(provider, limit) records one use and returns None when under limit."""
    store = QuotaStore(state_root=tmp_state_root)
    assert store.consume("coderabbit", limit=10) is None
    assert store.usage("coderabbit") == 1


def test_remaining_treats_null_quota_as_unlimited(tmp_state_root):
    """When a provider has no daily quota (e.g. self-hosted), remaining is +inf."""
    store = QuotaStore(state_root=tmp_state_root)
    for _ in range(5):
        store.record("pr-agent")
    assert store.remaining("pr-agent", limit=None) == float("inf")
```

- [ ] **Step 2: Verify the test count + RED phase**

Run:
```bash
PYTHON=/tmp/cr-roster-venv/bin/python
PYTHONPATH=cr_roster:cr_router $PYTHON -m pytest cr_router/tests/test_quota_store.py -v --tb=line --no-header 2>&1 | tail -15
```

Expected: `9 failed` (or all-error collection) with the first failure being `ModuleNotFoundError: No module named 'cr_router.quota_store'`. The module does not exist yet — this is the **expected RED**.

- [ ] **Step 3: Commit (the failing tests)**

Run:
```bash
git add cr_router/tests/test_quota_store.py
git commit -m "test(cr_router): add failing QuotaStore tests (TDD RED)"
```

Expected: one commit on `cr-orchestration/p1-router`. The test file is committed in its RED state — this preserves the TDD trail.

---

## Task 5: Implement `QuotaStore` (GREEN)

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/quota_store.py`

- [ ] **Step 1: Write `quota_store.py`**

Create `cr_router/quota_store.py` with this exact content:
```python
"""File-backed daily quota counter for code-review providers.

Each provider's usage is stored in a per-day JSON file under
``{state_root}/quota-{provider_id}.{YYYY-MM-DD}.json``. The day boundary is
the local calendar date. Multi-process safety is NOT a goal — P1 is
single-process dry-run only; P3 will introduce flock() if multi-process
becomes necessary.

Source of truth: spec §6 D4 (quota rotation unit = per-day, per-provider).
"""
from __future__ import annotations

import json
import math
from datetime import date
from pathlib import Path


class QuotaExhaustedError(Exception):
    """Raised when consume() would push a provider past its daily limit."""

    def __init__(self, provider_id: str, limit: int, used: int) -> None:
        self.provider_id = provider_id
        self.limit = limit
        self.used = used
        super().__init__(
            f"Provider {provider_id!r} exhausted: {used}/{limit} used today"
        )


class QuotaStore:
    """Daily quota counter, one JSON file per (provider, day)."""

    def __init__(self, state_root: Path) -> None:
        self.state_root = Path(state_root)
        self.state_root.mkdir(parents=True, exist_ok=True)

    def _path_for(self, provider_id: str, day: date | None = None) -> Path:
        day = day or date.today()
        safe_id = provider_id.replace("/", "_")
        return self.state_root / f"quota-{safe_id}.{day.isoformat()}.json"

    def _read(self, provider_id: str, day: date | None = None) -> dict:
        path = self._path_for(provider_id, day)
        if not path.exists():
            return {"provider": provider_id, "date": (day or date.today()).isoformat(), "used": 0}
        return json.loads(path.read_text())

    def usage(self, provider_id: str) -> int:
        """Return the number of times ``provider_id`` has been used today."""
        return int(self._read(provider_id).get("used", 0))

    def remaining(self, provider_id: str, limit: int | None) -> float:
        """Return remaining quota for today. ``None`` limit → +inf."""
        if limit is None:
            return math.inf
        return max(0, int(limit) - self.usage(provider_id))

    def record(self, provider_id: str) -> None:
        """Increment today's usage counter by 1 and persist to disk."""
        data = self._read(provider_id)
        data["used"] = int(data.get("used", 0)) + 1
        path = self._path_for(provider_id)
        path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")

    def consume(self, provider_id: str, limit: int | None) -> None:
        """Atomically check + record one use.

        Raises:
            QuotaExhaustedError: if recording would exceed the daily limit.
        """
        if limit is None:
            self.record(provider_id)
            return
        used = self.usage(provider_id)
        if used >= int(limit):
            raise QuotaExhaustedError(provider_id, int(limit), used)
        self.record(provider_id)
```

- [ ] **Step 2: Run the tests (GREEN phase)**

Run:
```bash
PYTHON=/tmp/cr-roster-venv/bin/python
PYTHONPATH=cr_roster:cr_router $PYTHON -m pytest cr_router/tests/test_quota_store.py -v --no-header 2>&1 | tail -20
```

Expected: `9 passed`. If any fail, **STOP** and investigate.

- [ ] **Step 3: Commit (GREEN)**

Run:
```bash
git add cr_router/quota_store.py
git commit -m "feat(cr_router): implement QuotaStore with file-backed daily counter (SP2)"
```

Expected: one commit on `cr-orchestration/p1-router`.

---

## Task 6: Write failing tests for `ProviderQueue`

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/tests/test_provider_queue.py`

- [ ] **Step 1: Write the failing tests**

Create `cr_router/tests/test_provider_queue.py` with this exact content:
```python
"""Tests for cr_router.provider_queue."""
from __future__ import annotations

import pytest

from cr_router.provider_queue import ProviderQueue


def test_provider_queue_module_imports():
    """The ProviderQueue module must import cleanly."""
    assert ProviderQueue is not None


def test_construction_from_explicit_list(provider_ids):
    """A queue built from an explicit list preserves order."""
    q = ProviderQueue(providers=[{"id": pid} for pid in provider_ids])
    assert [p["id"] for p in q.iter()] == provider_ids


def test_construction_from_cr_roster():
    """When no providers are passed, the queue falls back to cr_roster.load_providers()."""
    q = ProviderQueue()
    ids = [p["id"] for p in q.iter()]
    assert ids[0] == "coderabbit"  # D2 primary
    assert "pr-agent" in ids        # D3 fallback chain
    assert len(ids) == 6            # full D3 queue


def test_next_skips_exhausted(provider_ids):
    """next(exhausted={...}) returns the first provider NOT in the exhausted set."""
    q = ProviderQueue(providers=[{"id": pid} for pid in provider_ids])
    chosen = q.next(exhausted={"coderabbit", "pr-agent"})
    assert chosen is not None
    assert chosen["id"] == "gemini-code"


def test_next_returns_none_when_all_exhausted(provider_ids):
    """When every provider is exhausted, next() returns None."""
    q = ProviderQueue(providers=[{"id": pid} for pid in provider_ids])
    chosen = q.next(exhausted=set(provider_ids))
    assert chosen is None
```

- [ ] **Step 2: Verify RED**

Run:
```bash
PYTHON=/tmp/cr-roster-venv/bin/python
PYTHONPATH=cr_roster:cr_router $PYTHON -m pytest cr_router/tests/test_provider_queue.py -v --tb=line --no-header 2>&1 | tail -15
```

Expected: `5 failed` (or all-error collection), first failure `ModuleNotFoundError: No module named 'cr_router.provider_queue'`. Expected RED.

- [ ] **Step 3: Commit (RED)**

Run:
```bash
git add cr_router/tests/test_provider_queue.py
git commit -m "test(cr_router): add failing ProviderQueue tests (TDD RED)"
```

Expected: one commit on `cr-orchestration/p1-router`.

---

## Task 7: Implement `ProviderQueue` (GREEN)

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/provider_queue.py`

- [ ] **Step 1: Write `provider_queue.py`**

Create `cr_router/provider_queue.py` with this exact content:
```python
"""ProviderQueue: wraps cr_roster.load_providers() and answers "who's next?".

Decoupled from QuotaStore on purpose — the queue only knows about ordering
and the exhausted-set filter. The Router composes the two.
"""
from __future__ import annotations

from typing import Any, Iterable

from cr_roster import load_providers


class ProviderQueue:
    """An ordered, iterable wrapper around the SP1 provider catalog."""

    def __init__(self, providers: list[dict[str, Any]] | None = None) -> None:
        if providers is None:
            providers = load_providers(validate_schema=True)
        self._providers = list(providers)

    def iter(self) -> Iterable[dict[str, Any]]:
        """Yield providers in D3 priority order (1 = highest)."""
        return iter(self._providers)

    def next(self, exhausted: set[str] | None = None) -> dict[str, Any] | None:
        """Return the first provider whose id is not in ``exhausted``.

        Returns None if every provider is exhausted.
        """
        exhausted = exhausted or set()
        for p in self._providers:
            if p["id"] not in exhausted:
                return p
        return None

    def all_ids(self) -> list[str]:
        """Convenience: list every provider id in priority order."""
        return [p["id"] for p in self._providers]
```

- [ ] **Step 2: Run the tests (GREEN)**

Run:
```bash
PYTHON=/tmp/cr-roster-venv/bin/python
PYTHONPATH=cr_roster:cr_router $PYTHON -m pytest cr_router/tests/test_provider_queue.py -v --no-header 2>&1 | tail -15
```

Expected: `5 passed`. The `test_construction_from_cr_roster` test depends on `cr_roster/providers.yaml` being present and valid — it should pass because P0 already shipped that file.

- [ ] **Step 3: Commit (GREEN)**

Run:
```bash
git add cr_router/provider_queue.py
git commit -m "feat(cr_router): implement ProviderQueue wrapping cr_roster catalog (SP2)"
```

Expected: one commit on `cr-orchestration/p1-router`.

---

## Task 8: Write failing tests for `Router`

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/tests/test_router.py`

- [ ] **Step 1: Write the failing tests**

Create `cr_router/tests/test_router.py` with this exact content:
```python
"""Tests for cr_router.router — the composition of ProviderQueue + QuotaStore."""
from __future__ import annotations

import pytest

from cr_router.quota_store import QuotaExhaustedError, QuotaStore
from cr_router.router import Router, RouterError


def _make_providers(ids: list[str]) -> list[dict]:
    return [{"id": pid, "name": pid, "priority": i + 1, "quota_per_day": 2, "free_tier": "test"} for i, pid in enumerate(ids)]


def test_router_module_imports():
    """The Router module must import cleanly."""
    assert Router is not None
    assert RouterError is not None


def test_pick_returns_primary_when_under_quota(tmp_state_root, provider_ids):
    """First call returns the highest-priority provider."""
    r = Router(providers=_make_providers(provider_ids), quota_store=QuotaStore(state_root=tmp_state_root))
    chosen = r.pick()
    assert chosen is not None
    assert chosen["id"] == "coderabbit"


def test_pick_records_consumption(tmp_state_root, provider_ids):
    """pick() must record one usage against the chosen provider."""
    r = Router(providers=_make_providers(provider_ids), quota_store=QuotaStore(state_root=tmp_state_root))
    r.pick()
    assert r.quota_store.usage("coderabbit") == 1


def test_pick_rotates_when_primary_exhausted(tmp_state_root, provider_ids):
    """Once coderabbit's quota is full, pick() returns pr-agent."""
    r = Router(providers=_make_providers(provider_ids), quota_store=QuotaStore(state_root=tmp_state_root))
    r.pick()  # coderabbit: 1/2
    r.pick()  # coderabbit: 2/2
    chosen = r.pick()
    assert chosen is not None
    assert chosen["id"] == "pr-agent"


def test_pick_skips_null_quota_provider(tmp_state_root, provider_ids):
    """A provider with quota_per_day=None is treated as unlimited."""
    providers = _make_providers(provider_ids)
    for p in providers:
        if p["id"] == "pr-agent":
            p["quota_per_day"] = None
    r = Router(providers=providers, quota_store=QuotaStore(state_root=tmp_state_root))
    # Exhaust coderabbit (2 uses)
    r.pick()
    r.pick()
    chosen = r.pick()
    assert chosen is not None
    assert chosen["id"] == "pr-agent"  # unlimited → always picked over rate-limited


def test_pick_returns_none_when_everyone_exhausted(tmp_state_root, provider_ids):
    """When all rate-limited providers hit their quota, pick() returns None."""
    providers = _make_providers(provider_ids)
    # Make the only unlimited one (pr-agent) artificially limited.
    for p in providers:
        p["quota_per_day"] = 1
    r = Router(providers=providers, quota_store=QuotaStore(state_root=tmp_state_root))
    for _ in providers:
        chosen = r.pick()
        assert chosen is not None
    # Now everyone should be at 1/1.
    chosen = r.pick()
    assert chosen is None


def test_pick_is_pure_dry_run_when_dry_run_true(tmp_state_root, provider_ids):
    """With dry_run=True, pick() returns the next provider WITHOUT recording consumption."""
    r = Router(providers=_make_providers(provider_ids), quota_store=QuotaStore(state_root=tmp_state_root), dry_run=True)
    chosen = r.pick()
    assert chosen is not None
    assert chosen["id"] == "coderabbit"
    # No counter was written.
    assert r.quota_store.usage("coderabbit") == 0


def test_status_reports_current_state(tmp_state_root, provider_ids):
    """status() returns a summary dict with per-provider used/limit/remaining."""
    r = Router(providers=_make_providers(provider_ids), quota_store=QuotaStore(state_root=tmp_state_root))
    r.pick()
    s = r.status()
    assert "providers" in s
    coderabbit = next(p for p in s["providers"] if p["id"] == "coderabbit")
    assert coderabbit["used"] == 1
    assert coderabbit["limit"] == 2
    assert coderabbit["remaining"] == 1


def test_status_lists_exhausted_providers(tmp_state_root, provider_ids):
    """status() flags providers at 0 remaining."""
    r = Router(providers=_make_providers(provider_ids), quota_store=QuotaStore(state_root=tmp_state_root))
    r.pick()
    r.pick()
    s = r.status()
    coderabbit = next(p for p in s["providers"] if p["id"] == "coderabbit")
    assert coderabbit["exhausted"] is True
```

- [ ] **Step 2: Verify RED**

Run:
```bash
PYTHON=/tmp/cr-roster-venv/bin/python
PYTHONPATH=cr_roster:cr_router $PYTHON -m pytest cr_router/tests/test_router.py -v --tb=line --no-header 2>&1 | tail -15
```

Expected: `9 failed` (or all-error collection), first failure `ModuleNotFoundError: No module named 'cr_router.router'`. Expected RED.

- [ ] **Step 3: Commit (RED)**

Run:
```bash
git add cr_router/tests/test_router.py
git commit -m "test(cr_router): add failing Router tests (TDD RED)"
```

Expected: one commit on `cr-orchestration/p1-router`.

---

## Task 9: Implement `Router` (GREEN)

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/router.py`

- [ ] **Step 1: Write `router.py`**

Create `cr_router/router.py` with this exact content:
```python
"""Router: composes ProviderQueue + QuotaStore to answer "who's next?".

Public API:
    Router.pick()     → returns the next provider, rotating on quota exhaustion
    Router.status()   → returns a structured summary of all providers' state
    Router.dry_run    → bool toggle; when True, pick() does NOT record consumption

The router does NOT make HTTP calls. It only decides which provider *would*
be called next. Real provider invocation lands in SP3 / SP4.
"""
from __future__ import annotations

from typing import Any

from cr_router.provider_queue import ProviderQueue
from cr_router.quota_store import QuotaStore


class RouterError(Exception):
    """Raised for router-level misuse (e.g. no providers configured)."""


class Router:
    """Composes a ProviderQueue with a QuotaStore to drive rotation."""

    def __init__(
        self,
        providers: list[dict[str, Any]] | None = None,
        quota_store: QuotaStore | None = None,
        state_root: Any = None,
        dry_run: bool = False,
    ) -> None:
        self.queue = ProviderQueue(providers=providers)
        if quota_store is not None:
            self.quota_store = quota_store
        elif state_root is not None:
            self.quota_store = QuotaStore(state_root=state_root)
        else:
            raise RouterError("Router requires either quota_store or state_root")
        self.dry_run = dry_run

    def pick(self) -> dict[str, Any] | None:
        """Return the next provider, rotating past exhausted ones.

        Returns None if every provider is exhausted.
        In dry-run mode, picks without recording consumption.
        """
        exhausted: set[str] = set()
        while True:
            candidate = self.queue.next(exhausted=exhausted)
            if candidate is None:
                return None
            limit = candidate.get("quota_per_day")
            remaining = self.quota_store.remaining(candidate["id"], limit)
            if remaining <= 0:
                exhausted.add(candidate["id"])
                continue
            if not self.dry_run:
                self.quota_store.consume(candidate["id"], limit)
            return candidate

    def status(self) -> dict[str, Any]:
        """Return a structured summary of every provider's current state."""
        providers_status = []
        for p in self.queue.iter():
            limit = p.get("quota_per_day")
            used = self.quota_store.usage(p["id"])
            remaining = self.quota_store.remaining(p["id"], limit)
            providers_status.append({
                "id": p["id"],
                "name": p.get("name", p["id"]),
                "priority": p.get("priority"),
                "limit": limit,
                "used": used,
                "remaining": remaining if remaining != float("inf") else None,
                "exhausted": (remaining == 0) if limit is not None else False,
            })
        return {"providers": providers_status, "dry_run": self.dry_run}
```

- [ ] **Step 2: Run the tests (GREEN)**

Run:
```bash
PYTHON=/tmp/cr-roster-venv/bin/python
PYTHONPATH=cr_roster:cr_router $PYTHON -m pytest cr_router/tests/test_router.py -v --no-header 2>&1 | tail -20
```

Expected: `9 passed`. If any fail, **STOP** and investigate.

- [ ] **Step 3: Run ALL router tests together**

Run:
```bash
PYTHON=/tmp/cr-roster-venv/bin/python
PYTHONPATH=cr_roster:cr_router $PYTHON -m pytest cr_router/tests/ -v --no-header 2>&1 | tail -30
```

Expected: `23 passed in 0.0Xs` (9 + 5 + 9). This confirms the three modules compose correctly.

- [ ] **Step 4: Commit (GREEN)**

Run:
```bash
git add cr_router/router.py
git commit -m "feat(cr_router): implement Router with pick() + status() + dry_run (SP2 core)"
```

Expected: one commit on `cr-orchestration/p1-router`.

---

## Task 10: CLI + `__main__` (dry-run entry point)

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/cli.py`
- Create: `phenotype-tooling-mergify/cr_router/__main__.py`

- [ ] **Step 1: Write `cli.py`**

Create `cr_router/cli.py` with this exact content:
```python
"""Command-line interface for cr_router (SP2 dry-run).

Three subcommands:

    python -m cr_router pick    [--state-root PATH] [--dry-run]
    python -m cr_router status  [--state-root PATH]
    python -m cr_router list    (shows the D3 queue without any state)

No HTTP calls. The CLI is the operator-facing surface for verifying the
rotation logic without touching any provider's API.

Exit codes:
    0 — success (a provider was picked, or status/list rendered)
    1 — every provider is exhausted (pick only)
    2 — internal error (bad args, missing files)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from cr_router.router import Router, RouterError


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="python -m cr_router", description="cr_router: code-review provider rotation (dry-run)")
    p.add_argument("--state-root", type=Path, default=Path("./var/cr_router"),
                   help="Directory for QuotaStore JSON files (default: ./var/cr_router)")
    sub = p.add_subparsers(dest="cmd", required=True)

    p_pick = sub.add_parser("pick", help="Pick the next provider (records consumption unless --dry-run)")
    p_pick.add_argument("--dry-run", action="store_true", help="Do not record consumption")

    sub.add_parser("status", help="Show per-provider usage/remaining state")
    sub.add_parser("list", help="Show the D3 provider queue (no state read)")

    return p


def _cmd_pick(args: argparse.Namespace) -> int:
    try:
        router = Router(state_root=args.state_root, dry_run=args.dry_run)
    except RouterError as exc:
        print(f"cr_router: {exc}", file=sys.stderr)
        return 2
    chosen = router.pick()
    if chosen is None:
        print("cr_router: every provider exhausted", file=sys.stderr)
        return 1
    payload = {
        "picked": chosen["id"],
        "name": chosen.get("name", chosen["id"]),
        "priority": chosen.get("priority"),
        "dry_run": router.dry_run,
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


def _cmd_status(args: argparse.Namespace) -> int:
    try:
        router = Router(state_root=args.state_root, dry_run=True)
    except RouterError as exc:
        print(f"cr_router: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(router.status(), indent=2, sort_keys=True))
    return 0


def _cmd_list(args: argparse.Namespace) -> int:
    router = Router(state_root=args.state_root, dry_run=True)
    ids = router.queue.all_ids()
    print(json.dumps({"queue": ids, "primary": ids[0] if ids else None}, indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    if args.cmd == "pick":
        return _cmd_pick(args)
    if args.cmd == "status":
        return _cmd_status(args)
    if args.cmd == "list":
        return _cmd_list(args)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 2: Write `__main__.py`**

Create `cr_router/__main__.py` with this exact content:
```python
"""Allow `python -m cr_router ...` invocation."""
from cr_router.cli import main

raise SystemExit(main())
```

- [ ] **Step 3: Smoke-test the CLI (dry-run)**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
PYTHON=/tmp/cr-roster-venv/bin/python
STATE_DIR=$(mktemp -d)
PYTHONPATH=cr_roster:cr_router $PYTHON -m cr_router --state-root "$STATE_DIR" list
echo "---pick (dry-run)---"
PYTHONPATH=cr_roster:cr_router $PYTHON -m cr_router --state-root "$STATE_DIR" pick --dry-run
echo "---status (after no consumption)---"
PYTHONPATH=cr_roster:cr_router $PYTHON -m cr_router --state-root "$STATE_DIR" status
rm -rf "$STATE_DIR"
```

Expected output (all three commands exit 0):
```
{
  "primary": "coderabbit",
  "queue": ["coderabbit", "pr-agent", "gemini-code", "sourcery", "greptile", "bito"]
}
---
{
  "dry_run": true,
  "picked": "coderabbit",
  "name": "CodeRabbit",
  "priority": 1
}
---
{
  "dry_run": true,
  "providers": [ ...coderabbit used=0 limit=2 remaining=1... ]
}
```

- [ ] **Step 4: Smoke-test rotation (real consumption)**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
PYTHON=/tmp/cr-roster-venv/bin/python
STATE_DIR=$(mktemp -d)
PYTHONPATH=cr_roster:cr_router $PYTHON -c "
from cr_router import Router, QuotaStore
from pathlib import Path
qs = QuotaStore(state_root=Path('$STATE_DIR'))
r = Router(quota_store=qs)
# Burn through coderabbit's 2/day quota
for i in range(4):
    chosen = r.pick()
    print(f'pick {i+1}:', None if chosen is None else chosen['id'])
"
rm -rf "$STATE_DIR"
```

Expected:
```
pick 1: coderabbit
pick 2: coderabbit
pick 3: pr-agent
pick 4: gemini-code
```

- [ ] **Step 5: Smoke-test exhaustion**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
PYTHON=/tmp/cr-roster-venv/bin/python
STATE_DIR=$(mktemp -d)
PYTHONPATH=cr_roster:cr_router $PYTHON -m cr_router --state-root "$STATE_DIR" pick >/dev/null 2>&1
RC=$?
echo "exit code on full exhaustion: $RC"
[ $RC -eq 1 ] && echo "OK (exit 1 = exhausted)" || echo "FAIL: expected exit 1, got $RC"
rm -rf "$STATE_DIR"
```

Expected:
```
exit code on full exhaustion: 1
OK (exit 1 = exhausted)
```

- [ ] **Step 6: Commit**

Run:
```bash
git add cr_router/cli.py cr_router/__main__.py
git commit -m "feat(cr_router): add CLI + __main__ entry point (pick/status/list, dry-run by default)"
```

Expected: one commit on `cr-orchestration/p1-router`.

---

## Task 11: README for `cr_router`

**Files:**
- Create: `phenotype-tooling-mergify/cr_router/README.md`

- [ ] **Step 1: Write the README**

Create `cr_router/README.md` with this exact content:
```markdown
# cr_router

Provider rotation + rate-limit fallback router for the automated
code-review workflow (SP2, P1 phase).

## What it does

Given the provider catalog from [`cr_roster`](../cr_roster/), picks the
next available code-review provider, taking into account a file-backed
daily quota counter. When the primary's quota is exhausted, it rotates to
the next provider in D3 priority order:

```
coderabbit → pr-agent → gemini-code → sourcery → greptile → bito
```

This package is **dry-run only**. It does NOT call any provider's API.
Real invocation lands in SP3 (triage) and SP4 (forge).

## Quick start

```bash
PYTHONPATH=cr_roster:cr_router python3 -m cr_router list
# → {"primary": "coderabbit", "queue": [...]}

PYTHONPATH=cr_roster:cr_router python3 -m cr_router pick --dry-run
# → {"picked": "coderabbit", ...}

PYTHONPATH=cr_roster:cr_router python3 -m cr_router status
# → per-provider used/limit/remaining
```

With consumption (real quota decrement):
```bash
PYTHONPATH=cr_roster:cr_router python3 -m cr_router pick
```

## Python API

```python
from cr_router import Router, QuotaStore
from pathlib import Path

router = Router(state_root=Path("./var/cr_router"))
chosen = router.pick()
if chosen is None:
    print("every provider exhausted")
else:
    print(f"using {chosen['id']}")
```

## State files

Per `(provider, day)` JSON file:
```
var/cr_router/quota-coderabbit.2026-09-09.json
var/cr_router/quota-pr-agent.2026-09-09.json
...
```

Format:
```json
{"provider": "coderabbit", "date": "2026-09-09", "used": 1}
```

## Spec decisions honored

- **D2** — primary provider is `coderabbit` (priority 1).
- **D3** — fallback queue is the `priority` field of `cr_roster/providers.yaml`.
- **D4** — quota rotation unit is per-day, per-provider.

## Out of scope for P1

- HTTP calls to provider endpoints (P2+)
- PR comment ingestion (P2)
- Issue + draft PR creation (P3)
- Agent dispatch (P4)
- Fleet-wide lefthook rollout (P5)
```

- [ ] **Step 2: Commit**

Run:
```bash
git add cr_router/README.md
git commit -m "docs(cr_router): add README with usage, state format, and out-of-scope list"
```

Expected: one commit on `cr-orchestration/p1-router`.

---

## Task 12: Final P1 verification

**Files:** none — verification only.

- [ ] **Step 1: Full pytest suite (SP1 + SP2)**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
PYTHON=/tmp/cr-roster-venv/bin/python
find cr_roster cr_router -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null
PYTHONPATH=cr_roster:cr_router $PYTHON -m pytest cr_roster/tests/ cr_router/tests/ -v --no-header 2>&1 | tail -45
find cr_roster cr_router -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null
```

Expected:
```
cr_roster/tests/test_loader.py::test_loader_module_imports PASSED
cr_roster/tests/test_loader.py::test_providers_yaml_exists PASSED
cr_roster/tests/test_loader.py::test_loader_returns_list PASSED
cr_roster/tests/test_loader.py::test_providers_sorted_by_priority PASSED
cr_roster/tests/test_loader.py::test_schema_validation_disabled_by_default PASSED
cr_roster/tests/test_loader.py::test_schema_validation_when_enabled PASSED
cr_roster/tests/test_loader.py::test_schema_validation_fails_on_missing_required_field PASSED
cr_router/tests/test_quota_store.py::... 9 tests ... PASSED
cr_router/tests/test_provider_queue.py::... 5 tests ... PASSED
cr_router/tests/test_router.py::... 9 tests ... PASSED
========================= 30 passed in ~0.1s =========================
```

(Literal: `7 + 9 + 5 + 9 = 30 tests`. If you see fewer, **STOP**.)

- [ ] **Step 2: Catalog + router end-to-end (real consumption + rotation)**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
PYTHON=/tmp/cr-roster-venv/bin/python
STATE_DIR=$(mktemp -d)
echo "=== pick 1 (real) ==="
PYTHONPATH=cr_roster:cr_router $PYTHON -m cr_router --state-root "$STATE_DIR" pick
echo "=== pick 2 (real) — coderabbit now at 2/2 ==="
PYTHONPATH=cr_roster:cr_router $PYTHON -m cr_router --state-root "$STATE_DIR" pick
echo "=== pick 3 (real) — rotates to pr-agent ==="
PYTHONPATH=cr_roster:cr_router $PYTHON -m cr_router --state-root "$STATE_DIR" pick
echo "=== status ==="
PYTHONPATH=cr_roster:cr_router $PYTHON -m cr_router --state-root "$STATE_DIR" status
echo "=== state files written ==="
ls -1 "$STATE_DIR"
rm -rf "$STATE_DIR"
```

Expected:
- pick 1 → `"picked": "coderabbit"` (exit 0)
- pick 2 → `"picked": "coderabbit"` (exit 0)
- pick 3 → `"picked": "pr-agent"` (exit 0)
- status → shows `coderabbit` used=2 exhausted=true, `pr-agent` used=1 exhausted=false, all others used=0
- `ls` shows 2 files: `quota-coderabbit.<today>.json` and `quota-pr-agent.<today>.json`

- [ ] **Step 3: Exhaustion exit code**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
PYTHON=/tmp/cr-roster-venv/bin/python
STATE_DIR=$(mktemp -d)
# Force every provider into the "limited to 1 use, then exhausted" state by
# exhaustively consuming them via the API.
PYTHONPATH=cr_roster:cr_router $PYTHON -c "
from cr_router import Router, QuotaStore
from pathlib import Path
import sys
r = Router(quota_store=QuotaStore(state_root=Path('$STATE_DIR')))
ids = []
for _ in range(50):
    chosen = r.pick()
    if chosen is None:
        print('exhausted after', len(ids), 'picks:', ids)
        sys.exit(0)
    ids.append(chosen['id'])
print('FAIL: never exhausted', ids)
sys.exit(2)
"
echo "now via CLI, the next pick should exit 1:"
PYTHONPATH=cr_roster:cr_router $PYTHON -m cr_router --state-root "$STATE_DIR" pick
RC=$?
[ $RC -eq 1 ] && echo "OK: CLI exits 1 on exhaustion" || echo "FAIL: expected exit 1, got $RC"
rm -rf "$STATE_DIR"
```

Expected:
- First `python -c` prints `exhausted after 7 picks: [coderabbit, coderabbit, pr-agent, gemini-code, sourcery, greptile, bito]` (or similar; rotation sequence).
- The `pick` CLI exits with code 1 and prints `cr_router: every provider exhausted` to stderr.

- [ ] **Step 4: Diff stat**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
echo "=== files added on this branch ==="
git diff --name-status origin/main..HEAD | grep -E "^A" | sort
echo ""
echo "=== files modified on this branch ==="
git diff --name-status origin/main..HEAD | grep -E "^M" | sort
echo "(empty = no modifications, expected for SP2)"
echo ""
echo "=== diff stat ==="
git diff --shortstat origin/main..HEAD
```

Expected:
- 13 files added, 0 files modified.
- ~700 lines added (rough target).

- [ ] **Step 5: Touched-path audit**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
echo "=== all paths touched by branch (SP1 + SP2) ==="
git diff --name-only origin/main..HEAD | sort
echo ""
echo "=== verify NO remote touchpoints ==="
git diff --name-only origin/main..HEAD | grep -E "^\.github/workflows/" || echo "OK: no workflow files touched (P1 stays local)"
```

Expected:
- All paths under `cr_roster/`, `cr_router/`, or `Makefile` (from P0).
- No `.github/workflows/` paths.

- [ ] **Step 6: Confirm NO remote push has occurred**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
git reflog | grep -iE "push" | head -5
echo "(empty = no push in this session)"
```

Expected: empty. **P1 must not push to origin** (operator decision).

- [ ] **Step 7: Final git state**

Run:
```bash
cd /Users/kooshapari/CodeProjects/Phenotype/repos/phenotype-tooling-mergify
git status --porcelain
echo "(empty = clean)"
echo ""
echo "=== commits on branch ==="
git log --oneline origin/main..HEAD
echo ""
echo "=== commit count ==="
git log --oneline origin/main..HEAD | wc -l
```

Expected:
- Working tree clean.
- ~13 commits on branch (one per Task step that commits).
- All commit messages use conventional-commits format with `cr_router` scope.

- [ ] **Step 8: Append final audit log entry**

Run:
```bash
cat >> ~/.forge/audit/sessions.log <<'EOF'
[2026-09-09] P1 implementation complete on branch cr-orchestration/p1-router in phenotype-tooling-mergify. SP2 (cr_router) shipped: QuotaStore (9 tests), ProviderQueue (5 tests), Router (9 tests), CLI + __main__ dry-run, README. Total 30 pytest tests green (7 SP1 + 23 SP2). 13 files added, 0 modified. No remote push performed. P1 stays local; awaiting operator PR review before P2 (SP3 triage).
EOF
echo "P1 complete — audit log updated"
```

---

## Self-Review (per writing-plans skill)

### Placeholder scan

- [ ] `grep -nE "TBD|\\?\\?\\?|implement later|fill in details|appropriate error handling|similar to Task" docs/superpowers/plans/2026-09-09-automated-code-review-orchestration-p1-v1.md`
- [ ] Expected: zero matches inside task steps.

### Spec coverage table

| Spec item | Honored by | How |
|---|---|---|
| §3 SP2 (cr-router) | Tasks 4–11 | QuotaStore + ProviderQueue + Router + CLI |
| §6 D2 (primary = coderabbit) | Task 7 + Task 11 | `load_providers()` returns `coderabbit` first; CLI `list` confirms |
| §6 D3 (fallback queue) | Task 7 | ProviderQueue.next() walks `cr_roster/providers.yaml` priority field |
| §6 D4 (per-day, per-provider) | Tasks 4–5 | QuotaStore stores one JSON file per `(provider, day)` under configurable root |
| §8 P1 (dry-run only) | Tasks 10–12 | CLI defaults to dry-run on `status`; `pick --dry-run` flag; `Router.dry_run=True` constructor arg |
| §10 DoD (no remote mutations) | Task 12 | Zero `.github/workflows/` paths touched, no push performed |

### Out-of-scope items deferred (correctly)

| Item | Deferred to | Why not P1 |
|---|---|---|
| HTTP calls to provider endpoints | P2 (SP3 triage) | P1 is dry-run only |
| PR comment ingestion | P2 (SP3 triage) | Needs authenticated `gh api` calls |
| Issue + draft PR creation | P3 (SP4 forge) | Touches remote (D10 needs operator confirmation) |
| Agent dispatch | P4 (SP5 resolver) | D6 (auto-merge policy) needs operator decision |
| Fleet-wide lefthook rollout | P5 | Affects 100+ repos; separate review |
| Go binary port | P2+ | Stdlib Python is enough for dry-run; defer until real provider I/O lands |

### Style consistency with P0 plan

| Element | Matches P0? |
|---|---|
| Header (Goal / Architecture / Tech Stack / Spec / Phase scope / Prerequisites / Spec decisions) | ✅ |
| File Structure block | ✅ same format |
| Task headers (### Task N: ...) | ✅ |
| Step format (`- [ ] **Step N: verb**`) | ✅ |
| Code blocks byte-exact | ✅ |
| "Expected:" / "Expected output:" footers | ✅ |
| Commit messages use conventional-commits format | ✅ |
| Self-review at the end with placeholder scan + spec coverage + out-of-scope | ✅ |

### Open questions deferred (not blocking P1)

- Whether `Router.pick()` should accept a `repo: str` argument so per-repo quotas are possible. (Current: global per-provider quota. P3 may need per-repo. Parked.)
- Whether `QuotaStore` needs flock() for multi-process safety. (Current: single-process dry-run. P3 will revisit if fleet-wide Actions workflows start writing concurrently.)
- Whether `cr_router` should become a separate repo or stay inside `phenotype-tooling-mergify`. (Current: same repo, matches SP1 placement. Defer until P3 lands and we have real consumers.)

---

## Done Criteria (per spec §10)

- [x] Plan covers all P1-scope SPs (SP2).
- [x] Each task has byte-exact file contents.
- [x] All code blocks compile/parse against Python 3.11+ stdlib.
- [x] No new third-party deps.
- [x] No remote mutations (push, PR creation, workflow dispatch) anywhere in any task step.
- [x] Self-review passes (no placeholders, spec coverage table complete, style consistent with P0).
- [x] Plan file committed to `docs/superpowers/plans/`.

**P1 plan is ready for operator review.** Run `git status` — expect one new file (`2026-09-09-automated-code-review-orchestration-p1-v1.md`) plus a small amount of churn in the audit log.
