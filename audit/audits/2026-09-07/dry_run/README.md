# Synthetic dry-run contract

This module validates an explicitly supplied **synthetic** manifest and writes
deterministic, additive candidate diagnostics. It never discovers inputs, reads
the historical snapshot, modifies originals, publishes results, or produces a
readiness grade.

## Synthetic verification
From the repository container root, run the focused synthetic suite:

```sh
python3 -m unittest discover -s research/audit-system/audits/2026-09-07/dry_run/tests -p 'test_dry_run.py'
```

This command is for synthetic fixtures only. It is not authorization to run a
snapshot migration or publish candidate artifacts.

## Real-input adapter (drafts only)

`snapshot_adapter.py` reads only explicitly enumerated legacy `criteria` JSON
files and returns an in-memory `snapshot-adapter/v1` manifest. It records the
source path, byte length, SHA-256, unchanged top-level envelope, and each row
at its exact `$.criteria[N]` locator. Its status is always `UNREVIEWED`.

Rubric rows lacking an exact source/domain/id identity and all scorecard rows
without a separately reviewed mapping are blocked; no status, applicability,
or qualified mapping is inferred. Unsupported shapes remain in the preserved
envelope and are reported as blockers. The adapter writes no files and never
calls `run_dry_run`; reviewed controls must separately turn this diagnostic
draft into a candidate manifest.

```python
from snapshot_adapter import build_draft_manifest

draft = build_draft_manifest(input_root, [
    {"path": "rubric/rubric-v1.json", "kind": "rubric"},
    {"path": "scorecards/Melosviz-audit.json", "kind": "card"},
])
```

Verify the adapter fixtures with:

```sh
python3 -m unittest discover -s research/audit-system/audits/2026-09-07/dry_run/tests -p 'test_snapshot_adapter.py'
```

## API
```python
run_dry_run(input_root, output_root, manifest)
```

`input_root` and `output_root` are explicit paths; the output root must be
outside the input root. `manifest` is an in-memory mapping. Unsafe, missing,
duplicated, non-array JSON inputs, and an already-existing candidate directory
raise `ContractError`.

Required manifest concepts include:

- `inputs`: nonempty, explicitly enumerated relative paths and nonempty `kind`s;
  each original byte stream is fingerprinted with length and SHA-256.
- `expected_baseline.rubric`: reviewed rubric `count` and `sha256`.
- `lineage` plus `reviewed_metadata`: assessed and declared subject/date;
  source path/hash; conversion, rubric, and scorer identity/version/hash; and
  one matching frozen capture timestamp.
- `applicability`: an explicit list of exact qualified keys, and `weights`:
  finite, nonnegative numeric weights. `implementation_version` and
  `capture_timestamp` participate in deterministic candidate identity.

Qualified keys are compact UTF-8 JSON serializations of
`["criterion-v2", source, domain, legacy_id]`. Components must be nonempty
strings and are preserved exactly; bare-ID matching and normalization are not
performed.

## Candidate diagnostics
The function creates one new `dry-run-candidate-<sha256>/` directory beneath
`output_root` and returns its path with these diagnostic-only objects:

- `inputs.json`, `identity-crosswalk.json`, `quarantine.json`, `lineage.json`,
  `applicability.json`, and `validation.json`.
- `validation.json` always includes `diagnostic_only`, sets
  `publication_allowed` to `false`, and sets `readiness_grade` to `null`.

Missing reviewed mappings, conflicting or duplicate qualified keys, unknown
subjects, unresolved applicable keys, incomplete lineage, invalid weights, or
input drift are blocked/quarantined. They are not inferred, substituted, or
converted into a readiness result.

Real snapshot execution, original-artifact changes, publication, and resolving
the documented missing mappings require separate explicit authorization.

## Recovered historical mapping compiler

`mapping_compiler.py` reproduces the preserved native Substrate-to-example
mapping from explicit row lists only. It emits qualified legacy and normalized
keys, never bare-ID references, and rejects unequal domain cardinalities,
title mismatches, duplicate domain/ID pairs, and ambiguous normalized titles.
It has no file discovery, output writing, status handling, or scoring path.

```python
from mapping_compiler import compile_mapping

mappings = compile_mapping("substrate-v3", legacy_rows, normalized_rows)
```

The historical crosswalk contains 13 colliding bare normalized IDs across
`documentation` and `dx`; qualified keys keep those identities distinct. The
compiler's compatibility fixture verifies the archived native-to-example path,
not the current Substrate card. Current-card mapping, applicability, lineage,
and publication remain separately blocked.
