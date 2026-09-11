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
