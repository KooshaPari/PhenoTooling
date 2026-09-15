# Synthetic dry-run contract implementation plan

**Goal:** provide a stdlib-only, synthetic-fixture-only validator that emits deterministic candidate diagnostics without reading or modifying the historical snapshot.

**Boundaries:** all code and tests remain in this directory. The public entry point accepts an explicit input root, output root, and frozen manifest. It rejects missing/unsafe paths and does not discover inputs or execute against the snapshot.

1. Add failing `unittest` cases for byte fingerprints, exact qualified-key identity, duplicate/conflict quarantine, row accounting, lineage/applicability blocks, deterministic output, and safe non-overwrite output.
2. Run the focused tests to record the expected import failure (RED).
3. Add a minimal `dry_run.py` using only the Python standard library: strict JSON decoding, validation, deterministic serialization, and additive output creation.
4. Run the focused suite, then inspect output/source hashes and requirement coverage (GREEN/self-review).

No commit, publication, real-snapshot invocation, source-data edit, network access, or dependency installation is in scope.
