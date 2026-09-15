# Approval proposal: identity and provenance contract

Status: PROPOSED, NOT APPROVED OR IMPLEMENTED. This supplements `RECONCILIATION.md`; it does not repeat its evidence inventory. Only this document is added. No source data, scorer, scorecards, INDEX, infrastructure, or remote changes are authorized by it.

## Next gate and sponsor decisions

Approve the contract below before implementing a migration. Existing evidence establishes cross-domain collisions, but not uniqueness of source/domain/legacy-ID tuples or intended subjects of ambiguous audit rows. These uncertainties must block automatic mapping, not be resolved by guesses.

| Decision requiring approval | Proposed default | Consequence |
|---|---|---|
| Identity | Versioned exact source/domain/legacy-ID tuple | Preserve unrelated controls sharing a legacy ID; no semantic deduplication |
| Ambiguity | Quarantine, fail publication | No last-wins, first-wins, majority vote, or inferred status |
| Missing lineage | Unverified and excluded from certification | No automatic registry score replacement or Tracera path substitution |
| Scoring applicability | Explicit reviewed applicable-control set | Missing assessments remain visible; no global readiness grade from a subset |
| Implementation scope | Add new versioned artifacts first | Existing snapshot and published artifacts remain preserved until separate replacement approval |

## Exact proposed identity mapping

Represent a logical key as JSON array `["criterion-v2", source, domain, legacy_id]`, serialized with UTF-8, `ensure_ascii=False`, and separators `(',', ':')`. Preserve each input string exactly: no case folding, trimming, renumbering, or source-name aliasing. Reject missing/non-string/empty key components. Use the canonical serialized string as the key, not a delimiter-concatenated value.

Example: `["criterion-v2","substrate-v3","architecture","A-0001"]` is distinct from `["criterion-v2","agileplus","agileplus","A-0001"]`. This is a proposed key contract, not proof that all current tuples are unique. Group by the complete tuple before migration; any repeated tuple is quarantined for explicit reviewer adjudication, including identical-content repetitions. Do not append an arbitrary suffix to make collisions disappear.

Give every original row a provenance locator consisting of the frozen rubric file SHA-256 and zero-based original row index. The lossless crosswalk records locator, untouched original row, proposed qualified key, and disposition `mapped` or `quarantined` with reason. Every row must occur exactly once in the crosswalk; original ordering is preserved as provenance, not used to select a winner. Unresolved rows cannot enter a publishable migrated rubric.

## Conflicting-input quarantine

Legacy audit rows map only through a reviewed subject/source/domain mapping, never solely by matching a bare ID. Preserve each audit's file SHA-256 and row index. Any one-to-many target, unresolved subject, duplicate qualified audit key, or conflicting statuses quarantines the entire affected key group. Preserve all rows and reasons. This includes identical duplicates until their disposition is reviewed. No implicit "missing" or "satisfied" replacement is permitted.

The 13 status-conflicting registry groups and two substrate groups identified in RECONCILIATION must remain explicit review items. A diagnostic output may enumerate quarantines and remaining assessments; a publishable score must fail while any applicable input is unresolved. An empty assessed set returns an explicit insufficient-evidence state, not a readiness grade.

## Source lineage policy

Each proposed audit envelope must carry assessed subject, exact source path/hash, source-declared subject/date, conversion identifier/version, rubric hash/version, scorer hash/version, capture timestamp, and reviewed applicability set. Unknown values remain explicit unknowns and block publication; filesystem modification time is not evidence of assessment time.

Registry's source card declares Melosviz: classify the recorded mapping as subject-mismatched, not a registry regression. Tracera's recorded path is missing: the inventoried alternative is only a candidate until subject/content/hash lineage is reviewed. Substrate lacks a recorded source: leave unresolved. Review the other three mappings too; file existence is insufficient. Preserve native and unified scores as different scales, with conversion metadata, never silently substitute one for the other.

## Proposed file changes after approval (all relative to audit-system)

| Target | Proposed operation |
|---|---|
| `audits/2026-09-07/identity-crosswalk-v2.json` | Add frozen row locators, proposed keys, original rows, dispositions |
| `audits/2026-09-07/input-quarantine-v2.json` | Add complete ambiguous groups and reviewer decision records |
| `audits/2026-09-07/source-lineage-v2.json` | Add six source mappings, hashes, subject checks and unresolved reasons |
| `rubric/schema-v2.json`, `rubric/rubric-v2.json` | Add versioned contract and approved migration; preserve v1 |
| `rubric/scoring-v2.py`, `rubric/tests/test_repair_contract.py` | Add fail-closed qualified-key scorer and deterministic fixtures; preserve scoring.py |
| `scorecards/v2/` | Add reviewed envelopes and regenerated output only after lineage gates |
| `scorecards/SUMMARY.json`, `INDEX.md` | Deferred replacement proposal only after comparison review and separate publication approval |

## Deterministic acceptance checks

| Check | Exact expected result |
|---|---|
| Preservation | Crosswalk has 4503 distinct original locators; original rows reconstruct byte-equivalent JSON values; frozen original file hash unchanged |
| Identity separation | Two A-0001 fixtures with different source/domain yield distinct keys; one assessment cannot score both |
| Full-tuple collision | Two identical proposed keys produce quarantine and a publication error, regardless of row order |
| Input conflict | Opposite statuses for one qualified key quarantine both rows; reversing order changes neither disposition nor publication result |
| Lineage | Registry subject/Melosviz source mismatch, missing Tracera path, and absent substrate source each block publication independently |
| Denominator | Applicable set of two keys with one satisfied assessment reports applicable=2, assessed=1, unassessed=1; no whole-scope readiness grade |
| Invalid/empty input | Unknown status, null/negative/nonfinite weight or unresolved key fails validation; zero assessed keys reports insufficient evidence |
| Reproducibility | Same canonical approved inputs and versions produce identical output bytes, excluding no hidden time/random fields |

Proposed verification command after implementation: `python3 -B -m unittest discover -s rubric/tests -p test_repair_contract.py -v`. The named tests and migrated artifacts do not exist as a result of this proposal and were not run. A complete executable implementation plan and concrete fixture code follow contract approval; this document is an approval-ready specification, not permission to implement.

Document verification: read the five decisions in RECONCILIATION; add this proposal; read it back. No new corpus or source investigation was performed. Coverage-ledger/privacy gates from AUDIT-HANDOFF remain open and are not superseded.
