# Dry-run migration specification

User approved REPAIR-PROPOSAL.md policies as the basis for this specification. Approval does not authorize implementation, migration execution, publication, source changes, or replacement of existing artifacts. This document is the only added artifact; no dry run or acceptance test has executed.

## Frozen inputs and deterministic identity

Future authorized execution must explicitly enumerate `rubric/rubric-v1.json`, `rubric/schema.json`, `rubric/id-crosswalk.json`, `rubric/evidence-index.json`, `rubric/weights.json`, `rubric/scoring.py`, the six named audit cards in RECONCILIATION.md, `scorecards/SUMMARY.json`, and `INDEX.md`. Record relative path, byte length, and SHA-256 of each original byte stream before parsing. Explicitly listed source cards and reviewed mapping/applicability manifests are additional fingerprinted inputs; missing inputs remain blockers, not guessed replacements. No corpus scan or remote recollection is implicit.

Qualified key: UTF-8 serialization of `["criterion-v2", source, domain, legacy_id]` using JSON `ensure_ascii=False` and separators `(',', ':')`. Preserve strings exactly; reject absent, non-string, or empty components. Do not normalize case, whitespace, aliases, or numbering. Validate whole-tuple uniqueness; every repeated tuple, even identical content, enters quarantine. Uniqueness is not established by prior bare-ID counts.

Each rubric/audit row retains its original file hash and zero-based row index plus unchanged parsed row value. Crosswalk accounting must cover every original row exactly once with disposition mapped or quarantined. Expected historical rubric count is 4503; any input-count/hash drift requires a reviewed new baseline, not silent acceptance. Original bytes are preserved independently of candidate JSON serialization.

## Ambiguity, lineage, applicability

No bare-ID-only assignment, inferred status, first/last winner, majority vote, arbitrary suffix, or automatic source substitution. One-to-many mappings, duplicate qualified audit keys, conflicting statuses, or unknown subjects quarantine the entire affected group with all original rows and reason codes. The documented 13 registry and two substrate status-conflicting groups remain explicit review cases, not pre-resolved mappings.

Lineage requires reviewed assessed subject, source path/hash and declared subject/date, conversion identity/version, rubric/scorer hashes and versions, capture timestamp, and applicability set. Missing or mismatched values block publication. Registry/Melosviz mismatch, missing Tracera recorded path, and absent substrate source remain blocked branches until reviewed evidence resolves them. Native and unified scores retain separate scale identities.

Applicability is an explicitly reviewed set of qualified keys. Report applicable, assessed, and unassessed counts separately. Unresolved applicable rows withhold any readiness grade; an empty assessed set is insufficient evidence. This dry run proposes no scoring-policy changes or live readiness certification.

## Additive candidate outputs (future execution only)

Use a new `audits/2026-09-07/dry-run-candidate-<input-manifest-sha256>/` directory; never overwrite an existing directory. Proposed files: `inputs.json`, `identity-crosswalk.json`, `quarantine.json`, `lineage.json`, `applicability.json`, and `validation.json`. All are diagnostics/candidates, not replacements for rubric or scorecards. Serialize objects with sorted keys, UTF-8, compact separators, finite JSON numbers only, and one trailing newline; preserve row arrays in input order and sort set-like arrays by qualified key. No execution timestamp/random identifier enters deterministic output; approved capture timestamps are frozen input fields.

## Acceptance gates for later authorized implementation

| Gate | PASS condition; otherwise FAIL/BLOCKED |
|---|---|
| Source unchanged | Every explicit original input has identical pre/post SHA-256 and length; no original edited, deleted, renamed, or replaced |
| Accounting | Each input row locator occurs exactly once; mapped plus quarantined equals input count; original parsed values preserved |
| Identity | Distinct source/domain A-0001 fixtures remain distinct; repeated complete tuple quarantines every member |
| Conflict | Opposite statuses quarantine both rows; reversing input order preserves quarantine decision and withholds grade |
| Lineage | Wrong subject, missing path, or missing source independently blocks publication; no inferred substitute |
| Applicability | Two applicable keys with one assessed success report 2/1/1, not whole-scope 100% readiness |
| Reproducibility | Identical frozen inputs and implementation version produce byte-identical candidate files in two fresh directories |
| Fail closed | Invalid statuses/weights or unresolved applicable inputs withhold readiness grade; zero assessed reports insufficient evidence |

Next gate: separate authorization to implement and test this dry-run contract against synthetic fixtures, then authorization for snapshot execution. Policy approval alone does not resolve missing mappings, authorize original changes, or permit publication. Existing coverage/privacy gates remain open. Verification for this specification is document readback and line count only; future acceptance gates above are NOT RUN.
