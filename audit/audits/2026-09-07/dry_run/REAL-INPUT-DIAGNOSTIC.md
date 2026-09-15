# Real-input draft manifest — diagnostic report

Date: 2026-09-12. Status: **DIAGNOSTIC ONLY. UNREVIEWED. No approval, readiness, or publication.**

## What was done

Ran `snapshot_adapter.build_draft_manifest()` against the real rubric and all six
scorecards. This produces an in-memory UNREVIEWED draft; it does NOT run the
dry-run evaluator, produce a candidate, or authorize any action.

## Inputs processed

| File | Kind | Records | SHA-256 (prefix) | Size |
|---|---|---:|---|---:|
| `rubric/rubric-v1.json` | rubric | 4,503 | `e50b5c2875ef2ef0` | 1,346,995 B |
| `scorecards/Melosviz-audit.json` | card | 122 | `70a78bbad54826ad` | 7,719 B |
| `scorecards/SessionLedger-audit.json` | card | 122 | `5b91abbb11bab2e4` | 7,713 B |
| `scorecards/Tracera-wtrees-audit.json` | card | 47 | `08e4debd13d55254` | 2,997 B |
| `scorecards/phenotype-registry-audit.json` | card | 122 | `5b4cfb5c65a99ef3` | 7,501 B |
| `scorecards/sharecli-audit.json` | card | 122 | `0f213f8e5e477749` | 7,595 B |
| `scorecards/substrate-audit.json` | card | 140 | `669d605954524c41` | 8,869 B |
| **TOTAL** | | **5,178** | | |

## Rubric structure

Fields: `id`, `domain`, `title`, `status`, `evidence`, `notes`, `source`

Status distribution:
- `reference`: 2,294 (51.0%)
- `historical`: 2,069 (45.9%)
- `satisfied`: 126 (2.8%)
- `partial`: 14 (0.3%)

The rubric uses `source` (e.g., `substrate-v3`) and `domain` (e.g., `architecture`)
which form part of the qualified key `["criterion-v2", source, domain, id]`.

## Card structure

Fields: `id`, `status` only.

Cards do NOT contain `source`, `domain`, `title`, or `evidence`. This is why every
card record gets `missing_reviewed_mapping` -- the adapter cannot infer which rubric
row each card row maps to without an explicit reviewed mapping.

Status distribution per card:

| Card | satisfied | partial | missing | total |
|---|---:|---:|---:|---:|
| Melosviz | 109 | 13 | 0 | 122 |
| SessionLedger | 106 | 16 | 0 | 122 |
| Tracera-wtrees | 47 | 0 | 0 | 47 |
| phenotype-registry | 0 | 42 | 80 | 122 |
| sharecli | 47 | 75 | 0 | 122 |
| substrate | 126 | 14 | 0 | 140 |

## Key findings

1. **4,503 rubric rows** -- matches the historical count exactly.
2. **675 card rows** across 6 cards (122+122+47+122+122+140).
3. **Card rows have only `id` and `status`** -- a reviewed mapping is required to
   connect card rows to rubric rows via qualified keys.
4. **phenotype-registry has 80 "missing" rows** -- these criteria are absent from
   the registry's audit, not just unsatisfied.
5. **Draft manifest saved** at `DRAFT-MANIFEST-REAL-INPUTS.json` (3.8 MB,
   SHA-256 `7cfdfd108a2f5882...`).
6. **Status: UNREVIEWED** -- this is a diagnostic snapshot, not an approved input.

## What this enables

- A reviewer can now inspect the actual data shape and decide on mappings.
- The adapter has fingerprinted every real input file with SHA-256 and length.
- The draft manifest preserves the exact row values and locators for audit trail.
- This is the first time real inputs have been processed through the adapter.

## What this does NOT enable

- No dry-run evaluation was executed (would require reviewed mappings + lineage).
- No readiness grade, score, or certification is implied.
- No source binding, publication, or migration was attempted.
- All 675 card records remain `UNREVIEWED` with `missing_reviewed_mapping`.

## Saved artifact

```
audits/2026-09-07/dry_run/DRAFT-MANIFEST-REAL-INPUTS.json
  SHA-256: 7cfdfd108a2f5882f29d9f0b3738ca81892d32ccf86fadef0d5bb58da0761bd3
  Size: 3,842,045 bytes
  Status: UNREVIEWED diagnostic draft
```
