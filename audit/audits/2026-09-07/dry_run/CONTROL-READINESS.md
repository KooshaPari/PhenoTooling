# Control Readiness

Scope: dry-run review packet and manifest drafts only. No approvals are inferred.

## Required controls

| Control | Present | Readiness |
|---|---|---|
| Qualified-key mappings | Contract present; mappings absent for all six cards | BLOCKED |
| Explicit applicability sets | Policy/shape present; reviewed sets absent for all six cards | BLOCKED |
| Per-card lineage | Required-field list and draft slots present; reviewed values absent | BLOCKED |

## Controls and evidence present

- Frozen input inventory includes rubric, schema, crosswalk, evidence index, weights,
  scorer, summary, and index with hashes/lengths where recorded.
- Six card paths, hashes, lengths, and record counts are recorded.
- Qualified-key serialization contract is recorded; normalization and bare-ID mapping
  are forbidden; ambiguous rows quarantine until reviewed.
- Snapshot adapter contract/version/hash and fail-closed untranslated-row rule are recorded.
- Draft manifests explicitly set `draft_status: UNREVIEWED`, `sponsor_reviewed: false`,
  and publication false (lineage draft).
- Historical generator/crosswalk and deterministic dry-run test commands are documented,
  but do not establish current approval or provenance.

## Required controls absent or incomplete

- No reviewer decision (approve/reject) exists for any of the exactly three decisions.
- No card has a complete reviewed mapping or explicit reviewed applicability set.
- No card has approved lineage binding all required identity, source, date, conversion,
  rubric/scorer, capture, and applicability fields.
- Sponsor review, publication authorization, readiness grade, and approved lineage are absent.

## Exact UNKNOWN items

- Per-card qualified mappings and explicit applicability keys: Melosviz, SessionLedger,
  Tracera, phenotype-registry, sharecli, and Substrate.
- For every card: assessed subject, immutable source revision/hash, conversion identity/version,
  current rubric/scorer identity and versions/hashes, frozen capture timestamp, and applicability binding.
- Tracera: current-card conversion; native-to-unified selection rule; 435-point selection
  from 480 rules; recorded source path is missing.
- phenotype-registry: recorded source has a subject mismatch.
- Substrate: current mapping/order (historical example crosswalk shows drift); source path is absent.
- Recorded source paths for Melosviz, SessionLedger, and sharecli remain unverified.

## Exact BLOCKED items

- Publication, readiness, and current-card conversion are blocked until attestation/review.
- Real snapshot execution is blocked until all three decisions, reviewed manifests,
  complete input fingerprints, frozen capture metadata, and unchanged source bytes exist.
- Publication/replacement is blocked pending accounting, identity/conflict, lineage,
  applicability, reproducibility, and fail-closed gates plus all three approvals.
- Affected cards remain quarantined; no candidate may replace a source, scorecard, or rubric.

## Reviewer checklist

- [ ] Decide approve/reject for each card's explicit qualified-key mapping; reject inference,
  normalization, positional pairing, substitution, duplicates, conflicts, and one-to-many rows.
- [ ] Decide approve/reject each card's explicit applicability set; verify no keys-by-default.
- [ ] Decide approve/reject each card's lineage: subject, source path/hash, declared subject/date,
  conversion identity/version, rubric/scorer identity/version/hash, capture timestamp, applicability.
- [ ] Reconcile assessed and unassessed counts; quarantine unresolved identities and mismatches.
- [ ] Confirm frozen input hashes/timestamps and source bytes; record all three decisions explicitly.
- [ ] Keep publication false and do not execute migration or replace artifacts until gates pass.
