# Recovered generator provenance

Status: recovered historical implementation evidence; **UNREVIEWED** for any
current-card migration. This note does not change the rubric, crosswalk,
scorecards, drafts, or published scores.

## What generated the preserved artifacts

The preserved Codex session
`chats/codex/sessions/01a0606a-b33a-7e52-934a-7774d75843a2.jsonl` records two
ephemeral scripts executed on 2026-09-03:

| Time UTC | Temporary script | Output | Recovered behavior |
|---|---|---|---|
| 11:24:51 | `/tmp/normalize_rubric.py` | `rubric/rubric-v1.json` | Deduplicates `CONSOLIDATED_RUBRIC.json` by `(lowercase domain, normalized title)` and assigns per-domain title-sorted IDs. |
| 11:31:15 | `/tmp/crosswalk_weights.py` | `rubric/id-crosswalk.json` | Selects `source == substrate-v3`, groups by domain, title-sorts legacy and normalized rows, then pairs them positionally. |
| 11:31:29 | inline script | `rubric/example-audit.json` | Emits each crosswalk `unified_id` with its original legacy status. |

The scripts were written to `/tmp`, not retained as a versioned generator. The
session is therefore provenance evidence, not a reproducible generator release.

## Verified artifact chain

| Artifact | SHA-256 | Verified fact |
|---|---|---|
| `CONSOLIDATED_RUBRIC.json` | `701ace2d32d0fac06cd9e804cbb2b7d1ef6c3ae42126346c549045f2c4558c07` | Historical generator input. |
| `rubric/rubric-v1.json` | `e50b5c2875ef2ef00cf4b69e43f818373922852ac050914086aa1cc822f1dad6` | 4,503 criteria, v1.0, generated 2026-09-03. |
| `rubric/id-crosswalk.json` | `18267481af022e57b1148b092daf6a48753c4783bff7f7dc7f8cc308a537df9f` | 140 generated mappings. |
| `rubric/example-audit.json` | `5f50f0eb954385a99c55b43f0ff3b599f289c355b2a9d277bd934b1839c0288e` | Exactly the historical mapped-status demo. |

The recovered algorithm explains why native Substrate rows reproduce the
example audit, as recorded in `CONVERSION-RECONCILIATION.md`. It does **not**
explain or authorize mapping those rows to the current Substrate input.

## Why it cannot be applied to the current card

The normalizer generated ID prefixes from domain initials. Both `documentation`
and `dx` became `D`; the crosswalk consequently has 13 duplicate `D-0001`
through `D-0013` unified IDs, each assigned to two different legacy rows.
The crosswalk generator also used positional `zip` after title sorting and did
not record input hashes, lengths, generator version, or a cardinality check.

The current Substrate card has 128 positional-ID differences from the recovered
crosswalk. Applying it would therefore silently select one of two colliding
identities and turn an unreviewed historical reconstruction into a current
assessment. It remains quarantined.

## Safe next implementation gate

Implement a separately versioned, test-first mapping compiler that takes
fingerprinted inputs and emits qualified keys
`[criterion-v2, source, domain, legacy_id]`. It must reject duplicate complete
keys, unequal pairing lengths, and bare-ID references; preserve the recovered
140-row native-to-example mapping as a historical fixture; and produce no
current score or publication output until reviewed applicability and lineage
manifests exist.
