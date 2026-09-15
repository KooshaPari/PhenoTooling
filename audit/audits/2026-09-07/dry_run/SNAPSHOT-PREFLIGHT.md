# Snapshot dry-run preflight — BLOCKED

Date: 2026-09-09. Authorization permits one real dry run only when its
reviewed controls exist. No dry-run candidate was created or executed.

## Verified implementation

`dry_run.py` SHA-256 is
`999702a1bf4d5c5e81517864aec2196e94c15a219b4bbb20422876a07a80f087`,
matching the authorized frozen implementation.

## Explicit original inputs present and fingerprinted

- `rubric/rubric-v1.json`, `rubric/schema.json`, `rubric/id-crosswalk.json`,
  `rubric/evidence-index.json`, `rubric/weights.json`, `rubric/scoring.py`
- `scorecards/Melosviz-audit.json`, `scorecards/SessionLedger-audit.json`,
  `scorecards/Tracera-wtrees-audit.json`,
  `scorecards/phenotype-registry-audit.json`, `scorecards/sharecli-audit.json`,
  `scorecards/substrate-audit.json`, `scorecards/SUMMARY.json`, `INDEX.md`

## Blocking prerequisites

| Required reviewed control | Result | Exact evidence |
|---|---|---|
| Baseline count/hash | absent | no reviewed baseline declaration; policy says 4503 drift needs review |
| Qualified mapping and applicability set | absent | policy explicitly leaves 13 registry and 2 substrate conflicts for review |
| Lineage/metadata declarations | absent | no reviewed subject/source/hash/conversion/capture declarations |
| Tracera recorded source | missing | `repos/Tracera/fix-contract-tests-20260901/audit/SCORECARD-FULL-2026-08-30.md` |
| Substrate recorded source | absent | `RECONCILIATION.md` records no `source_card` |
| Real manifest adapter | unsupported | API accepts an explicit in-memory manifest; README declares synthetic-only |

The alternative Tracera path, Melosviz cards, and other extant paths are not
substitutes: their use would infer lineage or subject, which the contract bans.

## Required user decisions / safe next action

Provide separately reviewed, fingerprinted declarations for the baseline;
per-card qualified mapping and applicability; and each assessed subject, exact
source path/hash, source declaration/date, conversion, rubric/scorer versions,
and frozen capture timestamp. Resolve or explicitly quarantine Tracera and
substrate. Then authorize a real-input manifest adapter or provide a manifest
matching the existing API. Re-run this bounded preflight before one additive
candidate-only dry run.
