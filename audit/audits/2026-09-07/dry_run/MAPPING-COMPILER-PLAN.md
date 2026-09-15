# Qualified Mapping Compiler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use test-driven development. Steps use checkbox syntax for tracking.

**Goal:** Reproduce the historical native-to-example Substrate mapping using qualified identities, while rejecting the collision and positional-pairing failures that make it unsafe for the current card.

**Architecture:** A stdlib-only compiler accepts explicit legacy and normalized rows, groups them by exact domain, title-sorts with the recovered normalizer, and emits qualified legacy/normalized keys. It never reads scorecards, assigns statuses, writes artifacts, or produces grades.

**Tech Stack:** Python standard library and `unittest`.

---

### Task 1: Test the mapping contract

**Files:**
- Create: `dry_run/tests/test_mapping_compiler.py`
- Create: `dry_run/mapping_compiler.py`

- [x] **Step 1: Write failing tests** for exact qualified mappings, duplicate bare-ID isolation across domains, mismatched domain cardinality, and title mismatch.

- [x] **Step 2: Run RED**

Run: `python3 -B -m unittest discover -s research/audit-system/audits/2026-09-07/dry_run/tests -p 'test_mapping_compiler.py' -v`

Expected: FAIL because `mapping_compiler` does not exist.

- [x] **Step 3: Implement the minimal compiler** with no file discovery or output writes.

- [x] **Step 4: Run GREEN** using the same command; expect all mapping tests to pass.

### Task 2: Verify recovered historical compatibility

**Files:**
- Modify: `dry_run/tests/test_mapping_compiler.py`

- [x] **Step 1: Add a read-only compatibility test** that compares the compiler output with the 140 preserved `id-crosswalk.json` mappings.

- [x] **Step 2: Run RED** as part of the initial missing-module run, then add only the compiler needed to pass.

- [x] **Step 3: Run the focused mapping suite and the complete dry-run suite.**

Acceptance: 140 qualified mappings reproduce the historical fixture; no generated output is applied to the current card; unequal or title-mismatched inputs fail closed.
