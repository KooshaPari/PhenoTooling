# Independent Verification Report

Date: 2026-09-12. Verifier: independent_verifier.py

```
============================================================
INDEPENDENT VERIFICATION REPORT
============================================================

Step 1: Load draft manifest
  Loaded: 7 inputs

Step 2: Verify file fingerprints
  PASS  Draft status is UNREVIEWED
  PASS  Fingerprint matches for rubric/rubric-v1.json
  PASS  Fingerprint matches for scorecards/Melosviz-audit.json
  PASS  Fingerprint matches for scorecards/SessionLedger-audit.json
  PASS  Fingerprint matches for scorecards/Tracera-wtrees-audit.json
  PASS  Fingerprint matches for scorecards/phenotype-registry-audit.json
  PASS  Fingerprint matches for scorecards/sharecli-audit.json
  PASS  Fingerprint matches for scorecards/substrate-audit.json

Step 3: Verify rubric integrity
  PASS  Rubric has 4503 records (got 4503)
  PASS  All rubric records have source/domain/id (missing: 0)

Step 4: Verify card blockers
  PASS  Card Melosviz-audit.json: all 122 records have missing_reviewed_mapping
  PASS  Card SessionLedger-audit.json: all 122 records have missing_reviewed_mapping
  PASS  Card Tracera-wtrees-audit.json: all 47 records have missing_reviewed_mapping
  PASS  Card phenotype-registry-audit.json: all 122 records have missing_reviewed_mapping
  PASS  Card sharecli-audit.json: all 122 records have missing_reviewed_mapping
  PASS  Card substrate-audit.json: all 140 records have missing_reviewed_mapping

Step 5: Verify no publication authorization
  PASS  Draft has no publication_allowed field
  PASS  Draft has no readiness_grade field
  PASS  Draft has no score field

Step 6: Verify record locator integrity
  PASS  All record locators are valid (bad: 0)

Step 7: Verify status distribution
  PASS  Rubric has 126 satisfied (got 126)
  PASS  Rubric has 2294 reference (got 2294)
  PASS  Rubric has 2069 historical (got 2069)

Step 8: Verify evaluator rejects invalid inputs
  PASS  Evaluator sets publication_allowed=False
  PASS  Evaluator sets readiness_grade=None
  PASS  Evaluator includes diagnostic_only

============================================================
RESULT: 26 passed, 0 failed
============================================================
```

**All checks passed.** The evaluator output is consistent
with the source files. No publication was authorized.
