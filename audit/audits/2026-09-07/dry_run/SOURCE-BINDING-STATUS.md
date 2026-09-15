# Source Binding Status

Scope: local paths explicitly recorded by audit reports, plus the nearby roots
those reports named. Read-only inspection only; no equivalence is inferred.

## Recorded snapshot roots

| Field | Status | Concrete result |
|---|---|---|
| `audit-system/repos/substrate` exists | VERIFIED | Directory exists; `audit_scorecard.json` exists. |
| Snapshot Substrate README/manifest identity | UNKNOWN | No README or manifest found at bounded root depth; only scorecard identity is available. |
| Snapshot Substrate Git HEAD/remote/status | BLOCKED | `git rev-parse`, `remote`, and `status` each report not a Git repository. |
| `audit-system/repos/Tracera` exists | VERIFIED | Directory exists. |
| Recorded Tracera card | VERIFIED | Report-recorded `Tracera/fix-contract-tests-20260901/audit/SCORECARD-FULL-2026-08-30.md` is absent. |
| `audit-system/repos/Tracera` identity metadata | UNKNOWN | No authoritative README/manifest, HEAD, remote, or worktree metadata available. |
| `audit-system/repos/Tracera-wtrees/fix-contract-tests-20260901` exists | VERIFIED | Directory and report-recorded scorecard path exist. |
| Preserved Tracera card identity | VERIFIED | Card header is `Tracera Full-Stack Production Scorecard`; body records `tracera` @ `HEAD` (2026-08-30). |
| Preserved Tracera Git HEAD/remote/status | BLOCKED | Git commands report not a Git repository. |

## Nearby worktree roots

### Substrate

- **VERIFIED:** `/Users/kooshapari/CodeProjects/Phenotype/repos/substrate` exists,
  is a Git worktree, HEAD is `8ffb34f211f2ceba5c7e24530bf02c0b6600ff03`, and
  origin is `https://github.com/KooshaPari/substrate.git`.
- **VERIFIED:** README identifies `substrate` as an AI dispatch gateway/TUI.
- **VERIFIED:** nearby native card is `substrate/audit_scorecard.json`.
- **VERIFIED:** status is `main...origin/main [ahead 1, behind 1]`.
- **UNKNOWN:** card-declared audited commit `fe7dc66` is not established as this
  worktree HEAD; no equivalence or approval is inferred.

### Tracera

- **VERIFIED:** `/Users/kooshapari/CodeProjects/Phenotype/repos/pheno/Tracera`
  exists as a worktree rooted at `/Users/kooshapari/CodeProjects/Phenotype/repos/pheno`.
- **VERIFIED:** HEAD `f151ff6ae5a6ab67aeb59441226146933d922ba7`; origin
  `git@github.com:KooshaPari/pheno.git`.
- **VERIFIED:** status is on branch `feat/pheno-macos-signing-infisical-20260902T0046Z`
  tracking its origin branch.
- **UNKNOWN:** no bounded README/manifest or exact Tracera source-card path was found.

### Tracera-wtrees

- **VERIFIED:** `/Users/kooshapari/CodeProjects/Phenotype/repos/Tracera-wtrees`
  exists but is not itself a Git worktree.
- **VERIFIED:** named worktree card candidates include
  `validation-b9a173b-20260905/audit/SCORECARD-FULL-2026-08-30.md` and
  `workos-router-state-20260905/audit/SCORECARD-FULL-2026-08-30.md`.
- **UNKNOWN:** canonical worktree, repository remote/HEAD, and source binding.

## Binding conclusion

- Substrate nearby identity is **VERIFIED**, but snapshot-to-worktree binding is **UNKNOWN**.
- Tracera card existence/label is **VERIFIED**, but authoritative source binding is **UNKNOWN**.
- Missing inputs: authoritative snapshot README/manifest, Git revision for preserved
  snapshots, canonical Tracera worktree selection, and reviewed equivalence approval.
- Publication or replacement remains **BLOCKED** until those bindings are supplied.
