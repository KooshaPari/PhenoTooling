# Local resume consolidation - 2026-09-08

Latest metric-only revision, September 9: explicit user `keep 3\15` applied to all four variants as three teams / approximately 15 contributors. All four PDFs regenerated because each contained the old five-team claim; all remain one page and every revised page was visually inspected without clipping/overlap. Extracted PDF text confirms the corrected metric. Downloads originals untouched. Current PDF hashes supersede earlier checkpoint hashes:

| PDF | SHA256 |
|---|---|
| swe.pdf | 2ed8adc8e1c860b84caf1b6edd97f0f0bfd2d71339f5ddbb7efe01be9dd36f86 |
| pm.pdf | 0cd32bd017ae20cd6b1fc1599d73eb0159e041ed9d503482dab70cec45d87d8f |
| tpm.pdf | d5186f7c165e1feaf9e708f4597574f2b20b627ce73a52a405ae37f4a50d3dff |
| universal.pdf | f249e5c1647aa5a8f6f9242992bc3bdfa664cd162da382623ead7ca945e9bb62 |

## Current delivery - September 9, 04:03 PDT

All four conservative candidates now have editable Markdown/HTML and one-page Letter PDFs: [SWE](variants/swe.pdf), [PM](variants/pm.pdf), [TPM](variants/tpm.pdf), [universal](variants/universal.pdf). Every rendered page was inspected: consistent readable type, intact section boundaries, no clipping or overlap. All variants include Phenotype's variable leisure-time classification. These are local candidates for human review; no Google Docs copies, submissions or DOCX final. This delivery supersedes the historical pilot/status notes below.

| PDF | Pages | SHA256 |
|---|---|---|
| swe.pdf | 1 | 34f0ebd30d325c92fd6f478963a70dfa83e12c4f9127b3f1526e75349712527f |
| pm.pdf | 1 | 89759a6c05237e8e6131c45d9920b62e03d30e199b8a56b8e3b34977e7af474c |
| tpm.pdf | 1 | d0f487c9c8cd92e98e0b7f9690ebc6bb5d95849e5fdcf2c9d2dcdda18fe0d64b |
| universal.pdf | 1 | 876cab329ac8d253d669cc8145345d6d6d6235a17871405f0738e26dbcd8d3a0 |

Render evidence: `variants/{swe,pm,tpm,universal}-page-1.png`. Shared rendering used installed Chrome through an isolated Playwright browser, file URLs and no server. Re-rendering changes PDF timestamps/hashes. The factual source hierarchy is preserved in the claim ledger and `docs/2026-09-09-resume-finalization-gates.md`.

## Historical pilot and inventory notes

September 9 production checkpoint: [SWE PDF](variants/swe.pdf) is a one-page Letter candidate for human review, generated with installed Chrome and visually inspected on every page (one page): no clipping, overlap, orphan headings or duplicate employer records observed. Editable role candidates: [SWE](variants/swe.md), [PM](variants/pm.md), [TPM](variants/tpm.md), [universal](variants/universal.md). These use conservative source-backed wording; no dated M.S. expectation or optional uncertain metrics. Named employers are appropriate to this local resume context; LinkedIn anonymity remains a separate surface rule. PM/TPM/universal PDFs are not generated at this checkpoint. No DOCX final is claimed.

SWE PDF SHA256: `ada32405886057d417c5294e201ecd49157c972873a9ce1654fcf5c4d882357d`. SWE Markdown SHA256: `99b107078abf54af35c01e4e21caa09cda90ae5a19006b44fca118e05cc6fd60`. Render evidence: `variants/swe-page-1.png`; reproducible generation: `variants/build_candidates.py`, `variants/render.mjs`. Final PDF extracted text was checked through the skills/education footer. No installations or global browser/test server used.

Status: evidence pack and canonical content candidate complete; application-ready resume variants blocked on factual authority. No original files were changed, and no external documents were created.

- `source-manifest.json`: original absolute paths, file formats, byte sizes, SHA256 hashes and extracted-text hashes.
- `duplicate-groups.json`: identical normalized extracted-text groups; matching prose is not independent factual corroboration.
- `CLAIM_LEDGER.md`: conflicts, direct-user corrections recovered by the source workers, excluded sources and rendering limits.
- `CANONICAL_MASTER_CANDIDATE.md`: common experience queue and SWE/PM/TPM/universal selection contract. Contains explicit pending fields; do not submit.
- `extracted/`: source text keyed by manifest ID, including preserved out-of-scope filename matches identified in the ledger.
- `inventory.py`: reproducible read/extraction procedure. Do not rerun in place after source changes; create a new dated pack to preserve this snapshot.

Export boundary: [the active export contract](CANONICAL_MASTER_CANDIDATE.md#active-export-contract) contains exactly TWO records for the Akoma/Atoms pair: older Akoma and newer Atoms.Tech. This is not the total employer count for the resume. The candidate's NONEXPORT archive, named historical rows and two Stealth placeholders must never generate extra records. Choose display names for the target context; the LinkedIn-specific Stealth instruction does not automatically govern resume naming. Strip private aliases from any outward anonymous variant.

Finalization sequence: resolve remaining source-user references; lock product-specific metrics/dates/titles; choose bullets using the active export contract; author DOCX/PDF using available tooling; render and inspect every page; only then create later Google Docs copies under separate authorization.

No install, live Google Docs access, profile changes, submissions, Git operations, or deployment occurred.
