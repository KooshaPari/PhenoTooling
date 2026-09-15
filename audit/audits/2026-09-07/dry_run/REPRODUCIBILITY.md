# Synthetic cross-process reproducibility evidence
Scope: synthetic fixture only; no snapshot, network, publication, or source-data action.
Module: `dry_run.py`
SHA-256 before and after both runs: `999702a1bf4d5c5e81517864aec2196e94c15a219b4bbb20422876a07a80f087`
Frozen semantic inputs: `implementation_version=synthetic-v1`; valid fixture from
`tests/test_dry_run.py::DryRunContractTests.valid_frozen_manifest`.

Exact process pattern (separate fresh roots and Python processes):
```sh
MODULE=research/audit-system/audits/2026-09-07/dry_run
ROOT=$(mktemp -d /private/tmp/dryrun-repro-final-a.XXXXXX)
PYTHONHASHSEED=101 python3 -c '<runner below>' "$MODULE" "$ROOT"
ROOT=$(mktemp -d /private/tmp/dryrun-repro-final-b.XXXXXX)
PYTHONHASHSEED=202 python3 -c '<runner below>' "$MODULE" "$ROOT"
```
`<runner below>` imports that valid fixture, snapshots every input around `run_dry_run`, and hashes every returned `*.json`. Both exited 0; failures `[]`.
| Check | seed 101 | seed 202 | equal |
|---|---|---|---|
| candidate | `dry-run-candidate-b897c8dec71e7e2f9057b71005b8d8f9ed9bcff7109bc8394e0f8e7c63a87ffb` | same | yes |
| input bytes unchanged | true | true | yes |
| Output | SHA-256 in both processes |
|---|---|
| applicability.json | `7e494cfad3ff7fedd2da79e0f99442c4b0955c5a9c5fd6945cbbc1dd865adc15` |
| identity-crosswalk.json | `24bbe2376c3a0352049ae98a437a6812e8a902f31abd95e6a77de19a9a6d77f9` |
| inputs.json | `bd08e57d183f591a3ccd0441f730b35e6d06fcaf05674fa6f6c2d06281a28df3` |
| lineage.json | `0e887316b1d095531bc549e7a9848cb74a69c249054abb62daba3c8537abb1b9` |
| quarantine.json | `9f7ee9af3b6ad9e558e0a4ea51eba331d78e719b0246550529e656be79976fde` |
| validation.json | `e00d5d0aee4d2a17e884edeb1abeaa14ded7a17373e3265e65670b7e34ae303c` |
Input SHA-256, identical before/after and across roots:

| input | SHA-256 |
|---|---|
| audit.json | `453e7b28e3bda0311d369a9c95933322587de3b2364d7ce1bf34c8c6dce004a1` |
| capture.json | `3cd8c3a16b199a826a90c0a0108a8c23ec988b6b17218b546290a4f32b563051` |
| conversion.json | `92ea1e5e30777d684f00b4c67e3723c6e7418a5dc84a2fab9ea48c79e8ef754b` |
| rubric.json | `c5a850be633d138e77533310d5a1e8d39780510a3385a6025632d73f691d549c` |
| scorer.py | `7e4d6083acf010966d67f83506841c3fc48b7be1d7ad20cd64b0fab555a338a7` |
Result: PASS for this synthetic cross-process deterministic-output check.
