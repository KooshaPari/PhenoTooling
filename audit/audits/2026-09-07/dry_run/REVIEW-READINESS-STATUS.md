# Reviewer readiness status

Scope: local dry-run evidence and the decision slots in
`REVIEW-DECISIONS-PACKET.md`. This status does not record, infer, or authorize
any reviewer decision.

## Current disposition

All 18 card decision cells (six cards x mapping, applicability, and lineage)
are **PENDING**. Unresolved cells remain **BLOCKED**. The packet explicitly
records **NO APPROVAL RECORDED**; publication, migration, replacement, and
candidate promotion remain disallowed.

## Fields ready for reviewer entry

The following blank fields are available to complete when the required evidence
and authorization are supplied:

| Packet field | Readiness |
|---|---|
| Reviewer, UTC review date/time, review record ID | Blank slot ready to fill |
| Evidence/version reviewed | Existing local packet references are available |
| Per-card M/A/L decision cells | 18 `PENDING` slots ready for evidence-backed codes |
| Per-card M/A/L initials, date, exact evidence locator | Sign-off slots ready after each decision |
| Overall disposition | Must remain `NO APPROVAL RECORDED` until all required decisions and authorization exist |

`Sponsor authorization` is explicitly absent and is not a fillable approval
field from this packet alone.

## Decision-specific evidence still missing

| Decision | Required before entry | Current gap/status |
|---|---|---|
| M - qualified mapping | One reviewed `[criterion-v2,source,domain,legacy_id]` per row; explicit quarantine for duplicate, conflicting, one-to-many, and unresolved rows | Missing for Melosviz, SessionLedger, Tracera, phenotype-registry, sharecli, and Substrate; **UNKNOWN/BLOCKED** |
| A - applicability | Reviewed explicit qualified-key set with assessed/unassessed reconciliation and no default-all behavior | Missing for all six cards; **UNKNOWN/BLOCKED** |
| L - lineage | Assessed subject; immutable source path/hash; declared subject/date; conversion identity/version; rubric/scorer identity/version/hash; frozen capture timestamp; applicability binding | Missing or unapproved for all six cards; **UNKNOWN/BLOCKED** |

## Source and binding gaps

- The recorded Tracera source path is missing. The preserved Tracera-wtrees
  candidate is not a replacement and does not establish binding.
- phenotype-registry's recorded source has a subject mismatch.
- Substrate has no recorded source path; its current mapping/order differs from
  the historical example, and the nearby native card is not bound to it.
- Snapshot source bindings, immutable revisions, and reviewed equivalence are
  not established for the preserved Tracera/Substrate artifacts.
- Sponsor authorization, explicit reviewer decisions, and frozen capture
  metadata are absent. Draft controls remain `UNREVIEWED`; publication remains
  false.

## Entry gate

A reviewer may enter M, A, or L only with an exact evidence locator and the
criteria in `REVIEW-DECISIONS-PACKET.md`. A rejection leaves the affected card
quarantined and blocked. No candidate source substitution, inferred mapping,
or historical crosswalk inference is permitted.

**Explicit status: NO APPROVAL RECORDED.**
