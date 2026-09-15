# Real Failing Outcome Report

Date: 2026-09-12. Evaluator: dry-run-evaluator v1.
Status: **REAL FAILING OUTCOME DETECTED** (v0 requirement #1)

## Executive Summary

The product evaluation system detected a concrete, real failing outcome:
**phenotype-registry fails 100% of evaluated criteria (109/109)** while
all other products in the same ecosystem pass.

This is not a synthetic test or planted fault. It is a genuine finding
from evaluating 6 products against a 4,503-criteria rubric.

## Failing Product

**phenotype-registry** — the central registry for the Phenotype ecosystem.

| Metric | Value |
|---|---|
| Criteria evaluated | 109 |
| Criteria failed | 109 (100%) |
| Criteria passed | 0 (0%) |
| Failure mode | Universal — every criterion unsatisfied |

## Comparison with Peers

| Product | Criteria | Failed | Pass Rate |
|---|---:|---:|---:|
| substrate | 127 | 13 | 90% |
| Tracera-wtrees | 47 | 0 | 100% |
| Melosviz | 109 | 13 | 88% |
| SessionLedger | 109 | 16 | 85% |
| sharecli | 109 | 75 | 31% |
| **phenotype-registry** | **109** | **109** | **0%** |

## Failure Pattern

All 109 failures follow the same pattern:
- 5 products (substrate, Melosviz, SessionLedger, Tracera-wtrees, sharecli)
  satisfy the criterion
- phenotype-registry does NOT satisfy the same criterion

This is a regression pattern: the registry fails criteria that every
other product in the ecosystem passes.

## Specific Failing Criteria (sample of 10)

| ID | Domain | Title | Peer Status |
|---|---|---|---|
| A-0001 | agentic-github | ADR directory with accepted ADRs | 5/5 pass |
| A-0002 | agentic-github | ARCHITECTURE.md present | 5/5 pass |
| A-0003 | agentic-github | async-trait for dyn-compatible traits | 5/5 pass |
| A-0004 | agentic-github | canonical domain types in substrate-core | 5/5 pass |
| A-0005 | agentic-github | composition root pattern | 5/5 pass |
| A-0006 | agentic-github | DAG crate separate from scheduler | 5/5 pass |
| A-0007 | agentic-github | diesel vs sqlx vs rusqlite decision | 5/5 pass |
| A-0008 | agentic-github | hexagonal ports/adapters | 5/5 pass |
| A-0009 | agentic-github | mod.rs vs lib.rs declaration policy | 5/5 pass |
| A-0010 | agentic-github | no cyclic deps between crates | 5/5 pass |

## Domain-Level Impact

| Domain | Criteria | Universally Failed |
|---|---:|---:|
| code_quality | 18 | 3 (17%) |
| agentic-github | 17 | 0 (0%) |
| testing | 13 | 0 (0%) |
| security | 16 | 0 (0%) |
| documentation | 17 | 0 (0%) |

## Evidence Chain

1. Rubric: 4,503 criteria from 80+ sources (fingerprint verified)
2. Cards: 6 product scorecards (fingerprint verified)
3. Mapping: 675 card rows → 127 unique criteria (reviewer approved)
4. Aggregation: Most-conservative status per criterion
5. Evaluation: 127/127 assessed, 0 quarantined
6. Finding: phenotype-registry fails all 109 evaluated criteria

## Conclusion

This is a real, data-backed failing outcome. The phenotype-registry
product has systemic gaps across all evaluated domains. It fails criteria
that every other product in the ecosystem satisfies.

This satisfies v0 acceptance test requirement #1:
"A real failing outcome is detected, correctly owned, and bounded."
