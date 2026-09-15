# Reviewer Decision Packet — Card-to-Rubric Mapping

Date: 2026-09-12. Status: **AWAITING REVIEW**

## Summary

518 of 675 card rows are ambiguous (same ID appears in 2-4 rubric sources).
There are only **8 unique ambiguity patterns**. Resolving 8 decisions resolves
all 518 rows.

## Decision Format

For each pattern, pick ONE source. That source becomes the canonical rubric
row for all 518 rows matching this pattern.

## The 8 Decisions

### Decision 1: `substrate-v3` vs `DeepEval` (130 rows)
- **Pattern:** ID appears in `DeepEval` + `substrate-v3` (×2)
- **Cards affected:** substrate (130 rows)
- **Pick one:**
  - [ ] `substrate-v3` — canonical substrate criteria
  - [ ] `DeepEval` — DeepEval framework criteria
  - [ ] Other: _______________

### Decision 2: `substrate-v3` vs `third-party-research` (127 rows)
- **Pattern:** ID appears in `substrate-v3` + `third-party-research`
- **Cards affected:** Melosviz (27), SessionLedger (27), phenotype-registry (27), sharecli (27), Tracera-wtrees (4), substrate (15)
- **Pick one:**
  - [ ] `substrate-v3` — canonical substrate criteria
  - [ ] `third-party-research` — third-party sourced criteria
  - [ ] Other: _______________

### Decision 3: `agentic-research` vs `agileplus` vs `substrate-v3` (102 rows)
- **Pattern:** ID appears in all three sources
- **Cards affected:** Melosviz (24), SessionLedger (24), phenotype-registry (24), sharecli (24), substrate (6)
- **Pick one:**
  - [ ] `agentic-research` — agentic research criteria
  - [ ] `agileplus` — agile-plus criteria
  - [ ] `substrate-v3` — canonical substrate criteria
  - [ ] Other: _______________

### Decision 4: `CIS` vs `substrate-v3` (84 rows)
- **Pattern:** ID appears in `CIS` + `substrate-v3`
- **Cards affected:** Melosviz (21), SessionLedger (21), phenotype-registry (21), sharecli (21)
- **Pick one:**
  - [ ] `CIS` — CIS benchmark criteria
  - [ ] `substrate-v3` — canonical substrate criteria
  - [ ] Other: _______________

### Decision 5: `substrate-v3` vs `third-party-research` ×2 (25 rows)
- **Pattern:** ID appears in `substrate-v3` + `third-party-research` (×2)
- **Cards affected:** Melosviz (5), SessionLedger (5), phenotype-registry (5), sharecli (5), substrate (5)
- **Pick one:**
  - [ ] `substrate-v3` — canonical substrate criteria
  - [ ] `third-party-research` — third-party sourced criteria
  - [ ] Other: _______________

### Decision 6: `SLSA` + `SOX` vs `substrate-v3` vs `third-party-research` (24 rows)
- **Pattern:** ID appears in all four sources
- **Cards affected:** Melosviz (6), SessionLedger (6), phenotype-registry (6), sharecli (6)
- **Pick one:**
  - [ ] `SLSA` — supply chain security criteria
  - [ ] `SOX` — compliance criteria
  - [ ] `substrate-v3` — canonical substrate criteria
  - [ ] `third-party-research` — third-party sourced criteria
  - [ ] Other: _______________

### Decision 7: `DeepEval` vs `substrate-v3` (20 rows)
- **Pattern:** ID appears in `DeepEval` + `substrate-v3`
- **Cards affected:** Melosviz (5), SessionLedger (5), phenotype-registry (5), sharecli (5)
- **Pick one:**
  - [ ] `DeepEval` — DeepEval framework criteria
  - [ ] `substrate-v3` — canonical substrate criteria
  - [ ] Other: _______________

### Decision 8: `SOX` vs `substrate-v3` vs `third-party-research` (6 rows)
- **Pattern:** ID appears in all three sources
- **Cards affected:** Melosviz (2), SessionLedger (2), phenotype-registry (2)
- **Pick one:**
  - [ ] `SOX` — compliance criteria
  - [ ] `substrate-v3` — canonical substrate criteria
  - [ ] `third-party-research` — third-party sourced criteria
  - [ ] Other: _______________

## How to Resolve

1. Pick ONE source per decision above
2. Write the source name in the checkbox or "Other" field
3. Return this document

All 518 ambiguous rows will be resolved to the chosen source.
The 157 exact-match rows are already resolved (no action needed).
