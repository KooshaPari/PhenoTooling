# Dry-run review packet

**Scope:** Local evidence only. This packet is for review, not execution. The mapping, applicability, and lineage drafts are **UNREVIEWED**.

## 1. Exactly three approval decisions

Reviewers must make exactly these decisions:

1. **Qualified card mappings:** approve or reject each card's explicit qualified-key mapping; bare-ID inference, normalization, positional pairing, and substitution are not acceptable.
2. **Applicability:** approve or reject each card's explicit qualified-key applicability set; no keys-by-default policy is permitted.
3. **Lineage:** approve or reject each card's assessed subject, source path/hash, declared subject/date, conversion identity/version, rubric/scorer identity/version/hash, capture timestamp, and applicability binding.

## 2. Evidence versus attestation

**VERIFIED evidence:** draft card byte hashes, lengths, record counts, the six card paths, adapter contract/version/hash, qualified-key serialization contract, historical generator behavior, native Substrate-to-example reconciliation, and deterministic synthetic-test coverage are recorded locally. The baseline is 4,503 rubric criteria; the six cards contain 675 criteria.

**HISTORICAL evidence:** the recovered 2026-09-03 generator/session and its 140-row native Substrate-to-example crosswalk. It does not establish current-card conversion lineage or current scorecard provenance.

**UNKNOWN / must be attested:** per-card qualified mappings; explicit applicability keys; assessed subject and immutable source revision; conversion identity/version; current rubric/scorer identity and versions; frozen capture timestamp; and any Tracera 435-point selection rule.

**BLOCKED until attested:** publication, readiness, current-card conversion, and any replacement of an existing artifact. Draft manifests explicitly set sponsor review false and publication false.

## 3. Six-card fact register (no mappings inferred)

- **Melosviz:** `scorecards/Melosviz-audit.json`; SHA-256 `70a78bb...7d3d38`; 7,719 bytes; 122 records; mapping/applicability **UNKNOWN**; quarantine.
- **SessionLedger:** `scorecards/SessionLedger-audit.json`; SHA-256 `5b91ab...0ba1dd`; 7,713 bytes; 122 records; mapping/applicability **UNKNOWN**; quarantine.
- **Tracera:** `scorecards/Tracera-wtrees-audit.json`; SHA-256 `08e4de...f75aba1`; 2,997 bytes; 47 records; mapping/applicability **UNKNOWN**; quarantine. Candidate native source bytes are **VERIFIED** but conversion is **UNKNOWN**.
- **phenotype-registry:** `scorecards/phenotype-registry-audit.json`; SHA-256 `5b4cfb...f616255`; 7,501 bytes; 122 records; mapping/applicability **UNKNOWN**; quarantine. Recorded source has subject mismatch.
- **sharecli:** `scorecards/sharecli-audit.json`; SHA-256 `0f213f...9df45bbc`; 7,595 bytes; 122 records; mapping/applicability **UNKNOWN**; quarantine.
- **Substrate:** `scorecards/substrate-audit.json`; SHA-256 `669d60...bfb0ce`; 8,869 bytes; 140 records; mapping/applicability **UNKNOWN**; quarantine. Native candidate is **VERIFIED** bytes but current mapping/order drift is **UNKNOWN**.

## 4. Reviewer acceptance and rejection

**Accept only if:** every row has one reviewed complete `[criterion-v2,source,domain,legacy_id]`; duplicate/conflicting/one-to-many rows are quarantined; applicability is an explicit reviewed set; all assessed rows and unassessed rows are counted; and lineage fields match frozen input hashes and timestamps.

**Reject if:** any mapping is positional, bare-ID-only, normalized, inferred, or substituted; any applicable key is unresolved; any source subject/revision is missing or mismatched; any duplicate identity is last-wins; or any draft status is treated as approval. Rejection keeps the affected card **BLOCKED**.

## 5. Deterministic validation (dry run only)

```sh
python3 -m unittest discover -s research/audit-system/audits/2026-09-07/dry_run/tests -p 'test_dry_run.py'
python3 -m unittest discover -s research/audit-system/audits/2026-09-07/dry_run/tests -p 'test_snapshot_adapter.py'
python3 -m unittest discover -s research/audit-system/audits/2026-09-07/dry_run/tests -p 'test_mapping_compiler.py'
python3 -m json.tool audits/2026-09-07/dry_run/manifest-drafts/input-baseline-draft.json >/dev/null
python3 -m json.tool audits/2026-09-07/dry_run/manifest-drafts/mapping-applicability-draft.json >/dev/null
python3 -m json.tool audits/2026-09-07/dry_run/manifest-drafts/lineage-draft.json >/dev/null
```

These commands validate fixtures and draft syntax only; they do not approve controls or produce a score.

## 6. Execution gates

**Real snapshot gate — separate authorization required:** approve all three decisions, enumerate and fingerprint every required input, supply reviewed manifests, freeze capture metadata, and confirm source bytes are unchanged. Otherwise **BLOCKED**; do not run migration.

**Publication gate — separate authorization required:** real execution must pass accounting, identity, conflict, lineage, applicability, reproducibility, and fail-closed gates; publication remains false until a reviewer records all three approvals. No candidate replaces a source, scorecard, or rubric.
