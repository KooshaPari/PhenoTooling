# Rubric identity and scoring provenance reconciliation

Scope: read-only targeted analysis of the copied rubric, six scorecards, SUMMARY, and two MelosViz source cards. Only this report was added. No rubric, scorer, INDEX, source repository, infrastructure, or remote changed. Checks ran 2026-09-08 approximately 01:26 PDT and exited 0. Companion: `AUDIT-HANDOFF.md`.

## Identity findings

Grouping `rubric/rubric-v1.json` by literal `id` produces 4503 rows, 3598 IDs and 434 duplicated-ID groups. Every duplicated group spans multiple domains. Mutually exclusive classification gives 434 cross-domain groups, zero same-domain-only differing-content groups, zero exact-repeat-only groups. This does not mean cross-domain groups have no repeated fields; it means each group includes different domains.

| Multiplicity | Groups | Rows in groups | Excess rows |
|---|---:|---:|---:|
| 2 | 184 | 368 | 184 |
| 3 | 105 | 315 | 210 |
| 4 | 69 | 276 | 207 |
| 5 | 76 | 380 | 304 |
| Total | 434 | 1339 | 905 |

Arithmetic: 184+105+69+76=434; 368+315+276+380=1339; 184+210+207+304=905; 4503-905=3598. There are 3164 singleton IDs. Examples A-0001, A-0002 and A-0003 each collide across architecture/substrate-v3, agileplus/agileplus, and agentic-github/agentic-research. Bare IDs are therefore not globally unique identities. Do not delete rows as semantic duplicates.

## Score derivation

The current scorer builds a last-record-wins dictionary from audit IDs, then iterates every rubric row. A matching bare ID can therefore multiply one audit judgment across unrelated domains. For these cards all effective scored weights are represented by unit-weight arithmetic below. S=satisfied, P=partial, M=missing. Percent = 100*(S+0.5*P)/(S+P+M); these are duplicated rubric-row denominators, not unique control or whole-repository coverage.

| Card (`scorecards/`) | Input / unique IDs | Duplicate groups / status-conflicting groups | S / P / M | Recomputed percent |
|---|---:|---:|---|---:|
| Melosviz-audit.json | 122 / 109 | 13 / 0 | 222 / 13 / 0 | 97.23 |
| SessionLedger-audit.json | 122 / 109 | 13 / 0 | 198 / 37 / 0 | 92.13 |
| Tracera-wtrees-audit.json | 47 / 47 | 0 / 0 | 116 / 0 / 0 | 100.00 |
| phenotype-registry-audit.json | 122 / 109 | 13 / 13 | 0 / 107 / 128 | 22.77 |
| sharecli-audit.json | 122 / 109 | 13 / 0 | 98 / 137 / 0 | 70.85 |
| substrate-audit.json | 140 / 127 | 13 / 2 | 229 / 24 / 0 | 95.26 |

Registry arithmetic: 100*53.5/235=22.765957... ->22.77. Melosviz: 100*228.5/235=97.234042... ->97.23. The registry card begins A-0001=missing; Melosviz begins A-0001=satisfied. These inputs are not interchangeable. Conflicting duplicates make ordering consequential. No corrected score is proposed until the intended identity and source mappings are reviewed.

## Source-card mapping recorded in SUMMARY

All paths below are relative to `research/audit-system`. Existence was checked; existence alone is not provenance validation.

| SUMMARY repo | Recorded source_card | Result |
|---|---|---|
| Tracera | `repos/Tracera/fix-contract-tests-20260901/audit/SCORECARD-FULL-2026-08-30.md` | Missing; inventory instead has Tracera-wtrees/fix-contract-tests-20260901 path |
| Melosviz | `repos/Melosviz/audit/SCORECARD.md` | Exists; identifies KooshaPari/Melosviz, dated 2026-07-13 |
| phenotype-registry | `repos/phenotype-registry/audits/org-audit-snapshots/audit-v38/output/MelosViz/SCORECARD.md` | Exists; also identifies KooshaPari/Melosviz, dated 2026-07-13 |
| substrate | No source_card supplied | UNKNOWN lineage |
| SessionLedger | `repos/SessionLedger/SessionLedger/.claude/worktrees/mergify-configuration/audit/SCORECARD.md` | Exists; conversion lineage not reconstructed |
| sharecli | `repos/sharecli/audit/SCORECARD-v38.md` | Exists; unified conversion is not native v38 scale |

Both inspected MelosViz Markdown cards state native weighted overall 97.8%, grade A. Neither is a native phenotype-registry audit. The copied location under phenotype-registry does not make that repository the assessed subject. Content equivalence beyond targeted title/date/score lines was not asserted.

## Is 97.23 ->22.77 a regression?

No defensible temporal regression can be concluded. INDEX and SUMMARY publish registry 97.23 on the unified-score presentation, while current registry input recomputes 22.77 with the same existing engine and rubric. This is a reproducibility/provenance discrepancy on the claimed same scale. SUMMARY's recorded source is a MelosViz July-13 card; the audit JSON contains no repo/source/time metadata (only criteria). Generation inputs and chronology are not proven, so same subject/source/time cannot be assumed. Native MelosViz 97.8 and unified 97.23 are different mappings/scales; comparing those as a regression would also be invalid.

## Minimal repair decisions and acceptance gates (not executed)

| Decision | Proposed scope | Required acceptance test |
|---|---|---|
| Preserve semantic distinctions | Approve a source/domain-qualified stable key and lossless crosswalk before editing `rubric/rubric-v1.json` | All 4503 original rows mapped; all 434 collisions adjudicated; A-0001 judgments cannot leak between its three domains |
| Reject ambiguity at input | Propose scorer validation plus versioned audit envelope carrying subject, source hash, rubric/engine version, conversion ID, and timestamp | Duplicate audit keys fail deterministically; conflicting registry duplicates and two substrate conflicts cannot silently overwrite |
| Bind evidence to subjects | Review all six SUMMARY source mappings, repair only reviewed mappings | Registry cannot cite a card whose declared repo is Melosviz; every source exists with hash and approved assessed subject; substrate missing lineage blocks publication |
| Make scores reproducible | Regenerate SUMMARY and INDEX together only after identity and lineage gates | Saved input hashes, scorer version and exact command recreate all six published values; changes attributed to input/policy/mapping rather than presumed product regression |
| Preserve denominator honesty | Report assessed/applicable/unassessed counts separately; reject cross-domain multiplication | Synthetic rubric with same legacy ID in two domains requires explicit qualified judgments and cannot turn one success into two assessed controls |

Next authorized candidate is a decision/spec artifact for identity and provenance, not automatic data repair. Existing coverage-ledger and privacy/source-scope gates from the handoff remain open. Publication and source mutations still require explicit approval.

## Verification record

Targeted Python standard-library analysis grouped all rubric IDs; classified duplicated groups by distinct domain/content; counted audit duplicate/status-conflict groups; reproduced score percentages with independent status arithmetic; and checked all six SUMMARY source paths. Exit 0. `rg` checked title, date, and native overall lines in the two named MelosViz cards. Exit 0. No full corpus scan, remote refresh, repository test execution, or source conversion rerun was performed. Original scorer results remain diagnostic and uncertified.
