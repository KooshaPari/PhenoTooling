# Audit-system: evidence, state, and gated handoff

Scope: `research/audit-system` only. This is a snapshot audit and planning handoff, not a live portfolio certification. No source repository, infrastructure, remote, or private corpus was changed or recollected.

Evidence: `snapshot-evidence.json` (captured 2026-09-08 03:40 UTC, Python 3.9.6); `inspect_snapshot.py` was rerun successfully at 2026-09-08 06:35:22 UTC (2026-09-07 23:35 PDT, Python 3.14.6). The fresh output reconfirmed the counts and diagnostic outcomes below; it was displayed, not saved over the earlier snapshot. No claim of verification after that timestamp is made.

## Decision

NO-GO for treating the unified scores as whole-repository readiness or compliance certification. GO for preserving this evidence and reviewing the bounded repair plan. Implementation, corpus expansion, hosted checks, infrastructure access, and publication require separate scope approval.

## Past, present, future

| Area | Past / recorded claim | Present evidence | Future gate |
|---|---|---|---|
| Delivery | `INDEX.md` declares DELIVERED, 2026-09-03 | VERIFIED: artifacts exist; completion claims contradicted below | Correct claims only after reviewed repairs |
| Rubric/spec | 4503 unique criteria, 56 domains | VERIFIED: 4503 rows, 3598 unique IDs, 56 domains | Unique stable identity and validated schema |
| Corpus | INDEX describes research phase as complete | VERIFIED: file inventory, not full semantic reading | Source-by-source coverage and provenance ledger |
| Evidence | 4503/4503 resolved | VERIFIED: paths exist; most resolve to directories | Claim-level anchors, hashes, and scope |
| Scoring | Six generated cards and headline grades | VERIFIED: reproducible subset calculations, unsafe inputs | Validated inputs and explicit denominators |
| Tests/CI/e2e | Copied tests and workflow definitions | UNKNOWN: current source/hosted/runtime results | Commit-bound test and e2e evidence |
| Infrastructure | Collected local/Windows/history artifacts | UNKNOWN: current nodes, deployments, backups, ownership | Authorized read-only infrastructure inventory |
| Governance | Collected standards and historical audit records | HISTORICAL: not current compliance attestations | Versioned requirements and reviewed applicability |

## Verified snapshot inventory and defects

- 609 hashed files across 15 top-level groups; `audits/` and `docs/` excluded. This denominator is files, not sessions, repositories, requirements reviewed, or tests passed.
- 223/223 template-manifest entries match their recorded 12-character hash prefixes. Windows ZIP: 347 entries, no CRC failure. Neither proves source completeness or semantic correctness. `chat-collect-INCOMPLETE.tar.gz` was not integrity-tested by this inspector.
- Rubric: 434 duplicate-ID groups, 905 excess rows over unique IDs; 4247 rows violate the current schema's ID regex. Status counts: 126 satisfied, 14 partial, 2294 reference, 2069 historical.
- Evidence: 1158 file paths and 3345 directory paths, zero missing paths; 4320 auto resolutions and 183 fallback anchors. Declared resolved total is 4503 but the per-domain resolved sum is 4320. Existing paths do not prove claims.
- The scorer does not load `weights.json` or validate against `schema.json`. Duplicate rubric IDs can score one audit item repeatedly; duplicate audit IDs silently use the last item. One assessed success plus an unassessed item returns 100%; null weight raises TypeError; negative weights can return 200%; unknown statuses are silently skipped. The confidence interval is a code-described proxy, not validated statistical confidence.
- Six copied test-source files and 88 copied `.github/workflows` YAML files were identified by path patterns. They are corpus artifacts, not an audit-system test suite, not all estate tests, and not evidence they ran. No current hosted CI, integration, e2e, security, load, recovery, accessibility, or deployment acceptance run was performed.
- `git -C research/audit-system status --short` and `git log -1 --stat` failed: this directory is not a Git repository. Canonical ownership, commit provenance, and publication workflow remain unestablished; no Git mutation was attempted.

## Scores: reproducibility is not readiness

| Copied card (`scorecards/`) | Recomputed percent | Scored rubric rows / 4503 | Interpretation |
|---|---:|---:|---|
| Melosviz-audit.json | 97.23 | 235 (5.219%) | Subset only |
| SessionLedger-audit.json | 92.13 | 235 (5.219%) | Subset only |
| Tracera-wtrees-audit.json | 100.00 | 116 (2.576%) | Subset only |
| phenotype-registry-audit.json | 22.77 | 235 (5.219%) | INDEX/SUMMARY instead report 97.23 |
| sharecli-audit.json | 70.85 | 235 (5.219%) | Lossy unified mapping; native v38 is a different scope |
| substrate-audit.json | 95.26 | 253 (5.618%) | Subset only |

These row denominators are themselves affected by duplicate IDs. `SUMMARY.json` attributes phenotype-registry to a copied MelosViz source card; this is provenance drift requiring reconciliation, not proof of live registry quality. Its Tracera source path also differs from the inventoried Tracera-wtrees path. Do not average these grades into an estate score.

## Session preservation and coverage limits

Preserved Codex session `01a0606a-b33a-7e52-934a-7774d75843a2`: 3252 parseable JSONL records; SHA-256 `5d7f8ac16d0afd3c0bd70464f5664b3f3366eb12e6a54419494966a7182d8bee` matches the original in the fresh run. Timestamps span 2026-09-02 04:40:07 UTC to 2026-09-07 01:15:42 UTC. This verifies byte preservation and parsing, not full content review or task outcomes.

Codex index now has 8582 two-field rows, no duplicate first fields, and the preserved session row has a real tab before 3252. Only one indexed path resolves relative to the copied index; this does not establish missing originals. Claude/Forge/Cursor indexes use three columns with provider in column one, so the inspector's duplicate-first-field and relative-path diagnostics are not valid duplicate-session/missing-session findings for those formats. Provider-specific parsing is required. Full private corpus coverage is UNKNOWN.

## Gated WBS / implementation planning

Goal: establish a trustworthy, reproducible audit pipeline while preserving original evidence. Architecture: immutable snapshots -> typed provenance -> validated rubric -> deterministic scoring -> test evidence -> reviewed publication. Stack presently inspected: Python standard library, JSON/JSON Schema, TSV/CSV, Markdown. No implementation is authorized by this document.

| Step | Owner / dependencies | Bounded work and exact artifact targets | Acceptance gate |
|---|---|---|---|
| 1 | Evidence worker; sponsor scope approval | Create `audits/2026-09-07/coverage-ledger.tsv`; document source family, file hash, index format, expected/available/read counts, timestamp, privacy and retention class | Every inventoried family has a denominator or explicit UNKNOWN; no recollection without approval |
| 2 | Schema worker; step 1, identity-policy approval | Specify ID namespace and migration in `audits/2026-09-07/identity-contract.md`; propose changes to `rubric/schema.json`, `rubric/id-crosswalk.json`, `rubric/rubric-v1.json` | All 434 collision groups accounted for, lossless old-to-new mapping, zero unexplained ID violations; preserve originals |
| 3 | Evidence worker; steps 1-2 | Specify claim-level evidence contract in `audits/2026-09-07/evidence-contract.md`; propose `rubric/evidence-index.json` reconciliation | Each scored claim has exact file/hash/anchor, scope and freshness; directory/fallback references explicitly non-proving; totals reconcile |
| 4 | Scoring worker; steps 2-3, scoring-policy approval | Write red tests in proposed `rubric/tests/test_scoring.py`, then propose minimal `rubric/scoring.py` repair | Reject duplicate/unknown IDs, invalid statuses, null/negative/nonfinite weights; scores bounded 0-100; assessed/applicable/unassessed denominators explicit; weights policy tested |
| 5 | Quality worker; step 4, execution authority | Plan `rubric/tests/test_pipeline_e2e.py` with small synthetic fixtures and `audits/2026-09-07/quality-matrix.tsv` | Raw fixture -> normalization -> schema -> anchored evidence -> score -> rendered summary; deterministic golden result and corruption failures; exact commands, environment, exits saved |
| 6 | Independent reviewer; steps 1-5, publication approval | Recompute `scorecards/*.json`, reconcile `scorecards/SUMMARY.json` and `INDEX.md`; record decision in `audits/2026-09-07/release-gates.md` | Source-card mapping correct; no subset-as-readiness claims; current hosted/live/e2e checks separately PASS/FAIL/UNKNOWN; sponsor approves publication |

Within each approved implementation step: freeze input hashes; write the named failing test/contract; record the failure; make the minimal reviewed change; rerun and record results; review the diff. This is a gated WBS, not an executable code-complete repair specification. Steps 2-5 require their contracts and concrete fixture expectations before code changes. No commit/push is implicit.

```text
Audit-system handoff
|-- Snapshot inventory       [==========] 609/609 inventoried files hashed
|-- Template prefix checks   [==========] 223/223 matched
|-- ZIP CRC checks           [==========] 347/347 entries checked
|-- Diagnostics              [==========] 7/7 probes executed (defects found)
|-- Repair WBS               [..........] 0/6 implementation gates accepted
`-- Whole-estate readiness   [??????????] denominator and live evidence unknown
```

## Reproduction and limitations

From `/Users/kooshapari/CodeProjects/Phenotype/repos`, run `python3 -B research/audit-system/audits/2026-09-07/inspect_snapshot.py`. Fresh execution in this audit exited 0 and produced the results above. Exit 0 means the diagnostic collector completed, NOT that its findings passed. It hashes all in-scope files, reads the rubric/cards/indexes, imports only the local scoring implementation, parses one preserved session, and checks the ZIP; it does not semantically review all corpus contents, validate all JSON Schema constraints, execute copied tests, contact remote services, or establish regulatory compliance. Live standards refresh and broader source/infrastructure audits remain separately scoped future work.
