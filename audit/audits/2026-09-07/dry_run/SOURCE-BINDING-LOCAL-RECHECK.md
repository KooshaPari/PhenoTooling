# Source Binding Local Recheck

Date: 2026-09-11 UTC
Scope: filesystem existence, README/manifest identity, and local Git metadata only.
No network/SSH, builds/tests, source edits, equivalence inference, or remote writes.

## Commands used

- `test -e PATH` and `find PATH -maxdepth 2 ...`: existence/type and bounded
  README/manifest/card inspection.
- `sed -n '1,14p' README-or-manifest` and bounded card headers: identity text.
- `git -C PATH rev-parse --show-toplevel`, `rev-parse HEAD`,
  `branch --show-current`, local `config --get remote.origin.url`, and
  `status --short --branch`: run only on paths resolving as worktrees.

## Results

| Candidate or recorded input | Local result | Identity / Git result | Label |
|---|---|---|---|
| `research/audit-system/rubric/` | Directory exists; rubric JSON/CSV/Python files; no README/manifest at root | Artifact-tree identity is not declared by README/manifest | VERIFIED path; UNKNOWN identity |
| `research/audit-system/scorecards/` | Directory exists; seven JSON scorecards and `SUMMARY.json`; no README/manifest | Generated-artifact identity is not declared by README/manifest | VERIFIED path; UNKNOWN identity |
| Recorded Tracera card under `research/audit-system/repos/Tracera/fix-contract-tests-20260901/` | Exact `audit/SCORECARD-FULL-2026-08-30.md` is absent | No source card at the recorded path | VERIFIED absent |
| `research/audit-system/repos/Tracera/` | Directory and `audit/SCORECARD-S7778-REFRESH-2026-09-01.md` exist; no README/manifest | `git rev-parse` says not a repository; snapshot identity remains undeclared | VERIFIED path/card; UNKNOWN identity |
| `research/audit-system/repos/Tracera-wtrees/fix-contract-tests-20260901/` | Directory and exact full scorecard exist; no README/manifest | Card header says Tracera Full-Stack Production Scorecard, 2026-08-30, `tracera` @ `HEAD`; `git` says not a repository | VERIFIED card identity; UNKNOWN source binding |
| `research/audit-system/repos/substrate/` | Directory and `audit_scorecard.json` exist; no README/manifest | JSON declares `repo=kooshapari/substrate`, `branch_under_audit=main @ fe7dc66`; `git` says not a repository | VERIFIED card identity; UNKNOWN source binding |
| `/repos/pheno/Tracera` | Directory exists and is empty at the checked level; no README/manifest in candidate | Containing worktree `/repos/pheno`: HEAD `f151ff6ae5a6ab67aeb59441226146933d922ba7`, branch `feat/pheno-macos-signing-infisical-20260902T0046Z`, origin `git@github.com:KooshaPari/pheno.git`; parent README/Cargo identify Phenotype Infrastructure Kit | VERIFIED containing worktree; UNKNOWN candidate binding |
| `/repos/substrate` | Directory, README, Cargo workspace, and `audit_scorecard.json` exist | README identifies “substrate” AI dispatch gateway/TUI; HEAD `8ffb34f211f2ceba5c7e24530bf02c0b6600ff03`, branch `main`, origin `https://github.com/KooshaPari/substrate.git`, status `ahead 1, behind 1`; card declares `fe7dc66` | VERIFIED local identity/Git; UNKNOWN snapshot binding |
| `/repos/Tracera-wtrees/` | Directory exists; no root README/manifest; root is not a Git repository | Child candidates are the inspectable worktrees below | VERIFIED path; UNKNOWN root identity |
| `Tracera-wtrees/validation-b9a173b-20260905/` | README, Cargo.toml, pyproject.toml, and full scorecard exist | README/Cargo identify Tracera; HEAD `b9a173beea1ff82d9fc8f710d763a0af6f50ec47`, detached `HEAD`, origin `https://github.com/KooshaPari/Tracera.git`; status clean relative to detached HEAD | VERIFIED identity/Git; UNKNOWN canonical binding |
| `Tracera-wtrees/workos-router-state-20260905/` | README, Cargo.toml, pyproject.toml, and full scorecard exist | README/Cargo identify Tracera; HEAD `8b27d3c0f9cd9aed543020e267c38d403d8c59c2`, branch `fix/tracera-workos-router-state-20260905`, origin `https://github.com/KooshaPari/Tracera.git`; status tracks origin branch | VERIFIED identity/Git; UNKNOWN canonical binding |
| `/repos/Tracera/` | README, Cargo.toml, pyproject.toml, and both audit scorecards exist | README/Cargo identify Tracera; HEAD `b9a173beea1ff82d9fc8f710d763a0af6f50ec47`, branch `main`, origin `https://github.com/KooshaPari/Tracera.git`; status `behind 2` | VERIFIED identity/Git; UNKNOWN canonical binding |

## Non-local references and conclusion

- Aliases `desktop-kooshapari-desk` and `kooshapari-desk`, plus the recorded
  Windows roots (`C:/...`, `D:/...`) and `D:/cargo-target-substrate...`, do
  not resolve to local filesystem paths in this environment. No remote probe
  was attempted. **BLOCKED** local verification.
- Snapshot card paths and nearby worktrees are present, but no canonical
  snapshot-to-worktree or Tracera-card authority is established. **UNKNOWN**.
- Any publication/replacement decision remains **BLOCKED** pending explicit
  authority and reviewed binding evidence.
