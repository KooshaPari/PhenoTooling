# Draft controls: unreviewed only

These additive drafts fingerprint the 8 core inputs and 6 named cards. They
preserve original-byte identities independently; they are not an executable
manifest, a reviewed baseline, or a grade. `sponsor_reviewed` is false in all
three JSON files.

| Control | Captured fact | Status |
|---|---|---|
| Baseline | `rubric-v1.json`: 4,503 criteria, 1,346,995 bytes | captured, not sponsor-reviewed |
| Cards | 6 cards, 675 criteria; adapter sees 5,178 records with rubric | unmapped/quarantined |
| Adapter | `snapshot-adapter/v1`, final SHA `83e80d4c...d00cd0cb`, reviewed by 25 tests | implemented; does not approve mappings |
| Identity | Exact qualified source/domain/legacy-ID only | no bare-ID inference |
| Applicability | No qualified-key set supplied | unknown; never all keys by default |
| Lineage | Preserved Tracera and Substrate candidates are fingerprinted | unreviewed conversion lineage blocks publication |

The control/adapter boundary is `snapshot-adapter/v1`: each card record retains
its raw value and `$.criteria[N]` locator. A record with
`missing_reviewed_mapping` has no qualified-key translation and remains in
quarantine. No adapter output is treated as a reviewed mapping.

## Remaining blockers

| Blocker | Agent can fix | Irreducible policy / user input |
|---|---|---|
| Baseline | Re-fingerprint after an authorized source change | Sponsor review of the frozen 4,503/hash baseline |
| Mapping and applicability | Validate supplied declarations and quarantine malformed rows | Reviewed per-card qualified mappings and explicit applicable-key sets |
| Lineage | Verify supplied local paths, hashes, and declarations | Reviewed assessed subject, source/date, conversion, versions, and frozen capture timestamp; candidate files are not replacements |

`SNAPSHOT-PREFLIGHT.md`'s synthetic-format adapter blocker is historical: the
adapter is now implemented and test-reviewed. The remaining blockers are only
reviewed mapping/applicability and reproducible legacy lineage. No core
execution, source mutation, publication, or readiness calculation occurred.

Desk lookup outcome: the permitted route `koosh@100.96.135.160` authenticated
with the existing known-host entry and supplied identity, but the read-only
encoded PowerShell payload stopped at parse time before root or WSL enumeration.
No remote lookup fact was obtained; the desk source location remains unknown.
