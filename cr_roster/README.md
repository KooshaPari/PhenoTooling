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
