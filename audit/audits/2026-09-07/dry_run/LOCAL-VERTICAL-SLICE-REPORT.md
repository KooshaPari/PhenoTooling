# Local vertical-slice probe — E1

Status: **COMPLETE for local synthetic qualification AND false-pass negative control; not a product score or certification.**

## Scope

- Authorization: user selected option 1, local-only vertical slice.
- Subject: the audit-system dry-run module/API boundary; identity remains proposal-only.
- Mutation boundary: no real six-card inputs, source repositories, remote systems,
  migration, publication, or existing source/report/JSON files were modified.
- Epoch: E1 local synthetic probe + false-pass negative control.

## Command and result

### Suite 1: Original synthetic tests (30 tests)

From `audits/2026-09-07/dry_run`:

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
```

Result: **44 tests passed** in 2.7s (30 original + 14 false-pass).

### Suite 2: Planted false-pass tests (14 tests)

```sh
python3 -m unittest tests/test_planted_false_pass.py -v
```

Result: **14/14 passed** — every planted fault was detected and rejected.

## Witness coverage

### Original suite (30 tests)
- Good-path coverage includes explicit manifests, qualified-key mapping, byte
  preservation, accounting, deterministic identity, and historical crosswalk
  reproduction.
- Bad-path coverage includes missing/invalid baseline or lineage, duplicate and
  conflicting keys, one-to-many mappings, duplicate locators, malformed/nonfinite
  input, unknown applicability, and invalid weights.
- Fail-closed behavior is asserted: unresolved or ambiguous controls quarantine
  affected rows and withhold a readiness grade/publication permission.

### False-pass suite (14 tests)
Each test plants ONE specific fault that a naive evaluator might silently pass:

| # | Planted fault | Evaluator response |
|---|---|---|
| 1 | Wrong baseline count (9999) | `baseline_drift` blocker |
| 2 | Wrong baseline SHA-256 | `baseline_drift` blocker |
| 3 | Duplicate qualified keys in rubric | All quarantined (`repeated_qualified_tuple` + `ambiguous_rubric_target`) |
| 4 | Conflicting statuses (satisfied + unsatisfied) | Both quarantined (`conflicting_statuses`) |
| 5 | NaN weight | `invalid_weights` blocker |
| 6 | Negative weight (-5) | `invalid_weights` blocker |
| 7 | Wrong lineage subject | `lineage_assessed_subject` / `lineage_subject_mismatch` |
| 8 | Empty lineage | Multiple `lineage_*` blockers |
| 9 | Unknown applicable key | `unresolved_applicable` blocker |
| 10 | One-to-many mapping | Quarantined (`one_to_many_mapping`) |
| 11 | Even "valid" manifest | `publication_allowed=False`, `readiness_grade=None`, `diagnostic_only` always present |
| 12 | Source byte drift (file tampered) | `source_changed` blocker |
| 13 | Fake "satisfied" with wrong subject | Quarantined (`unknown_subject`) |
| 14 | Missing expected_baseline | `missing_expected_baseline` blocker |

**All 14 false-pass scenarios were correctly rejected.** This is v0 acceptance
test requirement #6: "a planted false pass is rejected."

## Findings

- **VERIFIED:** the local implementation and synthetic evaluator suite execute
  successfully and exercise both positive and negative controls.
- **VERIFIED:** the evaluator rejects 14 distinct planted false-pass scenarios,
  including wrong baseline, duplicate keys, conflicting statuses, invalid weights,
  wrong lineage, unknown applicability, one-to-many mapping, source drift, and
  fake satisfied status with wrong subject.
- **VERIFIED:** the evaluator NEVER sets `publication_allowed=True` and NEVER
  produces a readiness grade in synthetic mode.
- **VERIFIED:** this probe did not establish a real repository/product outcome,
  consumer benefit, source lineage, or reviewer approval.
- **BLOCKED:** real candidate execution still requires authoritative source
  bindings, reviewed mappings/applicability/lineage, and a frozen manifest.
- **LIMITATION:** a passing local suite validates the instrument contract, not the
  correctness of any six-card scorecard or lifecycle decision.

## Next discriminating action

Fill the reviewer packet and source bindings, then rerun the preflight before any
real-input candidate. Keep publication false until independent verification passes.
