# phenotype-registry Fix Plan

Date: 2026-09-12. Status: **ACTION REQUIRED**

## Problem

phenotype-registry fails 100% of evaluated criteria:
- 80 criteria: **missing** (not evaluated at all)
- 42 criteria: **partial** (partially met)
- 0 criteria: **satisfied**

The scorecard also lacks titles for all criteria -- just IDs and statuses.

## Root Cause

The phenotype-registry scorecard (`scorecards/phenotype-registry-audit.json`)
was generated but never completed. It contains 122 criteria with only `id`
and `status` fields -- no `title`, no `evidence`, no `notes`.

## Comparison with Passing Products

| Product | Satisfied | Partial | Missing | Score |
|---|---:|---:|---:|---:|
| substrate | 126 | 14 | 0 | 95.0 |
| Melosviz | 109 | 13 | 0 | 94.7 |
| SessionLedger | 106 | 16 | 0 | 93.4 |
| Tracera-wtrees | 47 | 0 | 0 | 100.0 |
| sharecli | 47 | 75 | 0 | 69.3 |
| **phenotype-registry** | **0** | **42** | **80** | **17.2** |

## Fix Steps

1. **Add titles to all 122 criteria** -- map each ID to its rubric title
2. **Evaluate each "missing" criterion** -- check if the criterion exists
   in the phenotype-registry codebase
3. **Upgrade "partial" to "satisfied"** where evidence supports it
4. **Add evidence and notes** to each criterion
5. **Re-evaluate** with `python eval.py run --product phenotype-registry`

## Expected Outcome

If phenotype-registry meets the same criteria as substrate (which shares
109 of 127 IDs), the pass rate should rise from 0% to ~90%.

## Priority

HIGH -- phenotype-registry is the central registry for the ecosystem.
A 0% pass rate blocks the entire product line from publishing clean
scorecards.
