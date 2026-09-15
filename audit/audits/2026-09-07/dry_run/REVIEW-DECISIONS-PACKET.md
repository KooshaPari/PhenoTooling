# Reviewer Decision Packet

**Scope:** local dry-run evidence only. This packet records decision slots; it
does not infer mappings, applicability, lineage, approval, readiness, or release.

## Reviewer record

| Field | Entry |
|---|---|
| Reviewer | ______________________________ |
| Review date/time (UTC) | ______________________________ |
| Review record ID | ______________________________ |
| Evidence/version reviewed | `CONTROL-READINESS.md` and `REVIEW-PACKET.md` |
| Sponsor authorization | Not present; do not treat this packet as authorization |

## Decision matrix

Decision codes: **PENDING** = no approval recorded; **APPROVE** may be entered
only after the criteria below pass; **REJECT** keeps the card blocked.

| Card | Scorecard input | Mapping (M) | Applicability (A) | Lineage (L) |
|---|---|---|---|---|
| Melosviz | `scorecards/Melosviz-audit.json` (122 records) | PENDING | PENDING | PENDING |
| SessionLedger | `scorecards/SessionLedger-audit.json` (122 records) | PENDING | PENDING | PENDING |
| Tracera | `scorecards/Tracera-wtrees-audit.json` (47 records) | PENDING | PENDING | PENDING |
| phenotype-registry | `scorecards/phenotype-registry-audit.json` (122 records) | PENDING | PENDING | PENDING |
| sharecli | `scorecards/sharecli-audit.json` (122 records) | PENDING | PENDING | PENDING |
| Substrate | `scorecards/substrate-audit.json` (140 records) | PENDING | PENDING | PENDING |

For each cell, the reviewer must write one code, initials, date, and an exact
evidence locator. A blank, ambiguous, or unsupported cell remains **PENDING**.

## Decision standards

### M — qualified card mapping

Approve only when every row has exactly one reviewed, complete
`[criterion-v2,source,domain,legacy_id]` key and all duplicate, conflicting,
one-to-many, and unresolved rows have an explicit quarantine disposition.

Reject when mapping is bare-ID, normalized, positional, inferred, substituted,
last-wins, duplicate, conflicting, one-to-many, or otherwise incomplete.

### A — explicit applicability

Approve only when the reviewer approves an explicit set of qualified keys,
including the treatment of every assessed and unassessed row, with no unresolved
applicable key and no keys-by-default behavior.

Reject when the set is absent, inferred, defaulted to all keys, unresolved, or
not reconciled to the card's assessed/unassessed counts.

### L — per-card lineage

Approve only when assessed subject, immutable source path and hash, declared
subject/date, conversion identity/version, rubric and scorer identity/version/
hash, frozen capture timestamp, and applicability binding all match reviewed
inputs and evidence.

Reject when any required field is missing, mismatched, mutable/unverifiable, or
not tied to the reviewed card bytes and conversion.

## Default and release rule

- No decision is approved by this packet. Current default for all 18 cells is
  **PENDING / no approval**; unresolved cells are treated as **BLOCKED**.
- Any **REJECT** leaves that card quarantined and blocked. Do not substitute a
  candidate source or infer a mapping from historical crosswalk behavior.
- Publication, readiness, migration, replacement, and candidate promotion remain
  disallowed until all three decisions for the affected card are explicitly
  recorded and separately authorized.

## Reviewer sign-off

| Card | M initials/date/evidence | A initials/date/evidence | L initials/date/evidence |
|---|---|---|---|
| Melosviz | __________________ | __________________ | __________________ |
| SessionLedger | __________________ | __________________ | __________________ |
| Tracera | __________________ | __________________ | __________________ |
| phenotype-registry | __________________ | __________________ | __________________ |
| sharecli | __________________ | __________________ | __________________ |
| Substrate | __________________ | __________________ | __________________ |

**Overall disposition:** `NO APPROVAL RECORDED` unless every required cell has
an explicit, evidence-backed reviewer decision and separate authorization.
