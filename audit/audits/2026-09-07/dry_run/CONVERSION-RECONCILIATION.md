# Conversion reconciliation: bounded local evidence

Checked 2026-09-09. Read-only JSON joins, set comparisons and Markdown arithmetic; no original scorer execution, source changes, regenerated dataset or new grade.
Paths are relative to `research/audit-system/`. Full native-card/rubric/engine hashes remain in SOURCE-PROVENANCE.md.
Conclusion: current SUMMARY arithmetic is reproducible from current unified inputs; native-to-current-unified lineage is not established. All candidates remain UNREVIEWED.

| Check | Deterministic result | Interpretation |
|---|---|---|
| Native Substrate rows | 140: 126 satisfied + 14 partial; (126+14*0.5)/140=0.95 | Reproduces recorded native percentage |
| Native versus rubric identity | All 140 native domain/title pairs match substrate-v3 rubric rows, with zero status differences | No observed status-version drift between these preserved artifacts |
| Recorded crosswalk | Join native id to legacy_id, emit unified_id/status; 140 rows, zero title mismatches | Explicit existing mapping covers every native pillar |
| Crosswalk versus example | Sorted mapped id/status rows exactly equal rubric/example-audit.json | A reproducible native-to-example path exists |
| Crosswalk versus current Substrate input | Native status sequence equals current 140-row status sequence; 128 positional IDs differ from crosswalk | Mapping/order drift evidence; generating cause/version unknown |
| Distinct status differences | 22 id/status values unique to each side after set comparison | Not 22 adjudicated criteria; duplicates require qualification |
| Current Substrate arithmetic | Last-ID-wins reduces 140 rows to 127 IDs; rubric matching yields 229 satisfied + 24 partial; (229+24*0.5)/253*100 rounds to recorded 95.26 | Reproduces legacy arithmetic only, with collision contamination |
| Current Tracera arithmetic | 47 unique satisfied IDs match 116 rubric rows; 116/116*100=recorded 100 | Reproduces legacy arithmetic only |
| Tracera ID selection | Its 47 IDs exactly equal substrate-v3 architecture(17), security(16), ci_cd(14) IDs | No recorded rule maps native L# pillars to this particular selection |

Substrate positional ID differences by domain: architecture 14, ci_cd 14, code_quality 18, documentation 15, dx 13, observability 8, release_engineering 11, security 15, supply_chain 7, testing 13; total 128.
Example: native CQ-04 rustfmt config is partial; crosswalk assigns CQ-0016, current input assigns CQ-0003 at the same position.
D-0006 and D-0009 remain conflicting bare-ID groups. IDs collide across documentation/dx and also DeepEval rubric rows; neither status selection nor criterion identity is approved.

## Tracera normalization qualification

Regex extraction of `### L#...score=N/M` found 96 pillars with earned/max totals 480/480.
Independent `## C...score=N/M` extraction found 11 cluster headers with earned/max totals 480/480.
Appendix D lines 1788-1848 explicitly documents 480 available points and describes 435 as weighted priorities / a prioritized subset.
It supplies no cluster weight vector, included/excluded pillar IDs, or executable selection rule. The missing 45 points equal nine full pillars, but no specific nine are implied.
The five evaluation-dimension percentages (30+25+20+15+10=100) describe evaluation within pillars; no text links them to the 435 total.
Thus the observed gap is underdocumented aggregation, not proof that the author intended an unweighted 435 sum. SOURCE-PROVENANCE.md is qualified accordingly.
Appendices F/G record document 1.0.0, Forge Engine v3.2, date 2026-08-30, working directory C:/Users/koosh/Tracera, branch HEAD and commit '(latest)'; no immutable commit or converter version.

## Recorded rules and exact artifact identities

`rubric/scoring.py` constructs a last-ID-wins dictionary, matches every rubric row by bare ID, uses satisfied=1/partial=0.5/missing=0 and per-audit-row weight default 1. It does not load weights.json or perform native-card conversion.
The crosswalk records only generated=true/count=140; both unified inputs and example contain only criteria, without conversion metadata.
Rubric metadata: scorecard-v3-unified/v1.0, generated_at 2026-09-03T04:24:51.916649; INDEX.md describes lossy cluster-to-domain mapping without a Tracera selection formula.
The copied Substrate scorecard_ci.py is a separate 88-pillar scanner; Tracera scorecard.yml invokes OpenSSF and loadtest/audit_scorecard.js is a k6 health check. None supplies the required conversion.

| Artifact | SHA-256 |
|---|---|
| rubric/example-audit.json | 5f50f0eb954385a99c55b43f0ff3b599f289c355b2a9d277bd934b1839c0288e |
| rubric/id-crosswalk.json | 18267481af022e57b1148b092daf6a48753c4783bff7f7dc7f8cc308a537df9f |
| rubric/scoring.py | faeb333db3e3db4aed2a6cecc6f5860dec4307b54ff881a40387e07493125034 |
| rubric/weights.json | 47306c886278d05f57e0d278a135c03de580a37fbf1e65fefb75e0d876a6f43c |
| INDEX.md | 6e0992d8d8242b3f37e504c4a6a4924b6e151c8cc1b3e322e5a69df04d8c7e4b |

Remaining agent work is locating recorded generator/version and immutable source revision, then proposing explicit qualified mappings. No new user choice is established by this slice; absent rules stay UNKNOWN rather than invented. No remote connection was made.
