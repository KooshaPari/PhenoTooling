# Provenance: `pheno-forge-scaffold` crate

This crate was ported **verbatim** from `KooshaPari/phenoForge@2fccbc27`
on 2026-09-10 during the phenoForge-batch recovery-hold closure.

## Source of record (canonical)

- Upstream repo: https://github.com/KooshaPari/phenoForge
- Upstream HEAD: `2fccbc27`
- Closure PR: https://github.com/KooshaPari/phenoForge/pull/41
- WBS row: `13-breadth-readiness-and-priority.md:32` (Recovery hold)
- Bounded target: "locate historical executable contract OR explicitly
  classify an unimplemented task/watch promise; sentinel must execute"
  (`06-future-wbs-governance.md:93`)

## Why this crate exists in `phenotype-tooling`

phenoForge's bounded target was satisfied by the **OR** arm — explicit
classification of the unimplemented state. PR #41 rewrote the documentation
to be truthful and added a 9-test negative-oracle suite + 1 `#[ignore]`
sentinel that locks the truthful state. Repo is documented as a
scaffold-with-truthful-disclosure.

The pattern — "documented scaffold + negative-oracle test suite + sentinel" —
is reusable for any other scaffolded tool that lands in `phenotype-tooling`.
This crate is the reference exemplar.

## What is in the crate (all verbatim copies)

| File                                               | Origin                                                            | Lines |
| -------------------------------------------------- | ----------------------------------------------------------------- | ----- |
| `crates/pheno-forge-scaffold/src/main.rs`          | phenoForge `src/main.rs` at HEAD `2fccbc27`                       | 12    |
| `crates/pheno-forge-scaffold/tests/integration.rs` | phenoForge `tests/integration.rs` at HEAD `2fccbc27` (via PR #41) | ~130  |
| `crates/pheno-forge-scaffold/src/lib.rs`           | new; provenance doc-comment only                                  | ~12   |

## What is NOT in this crate

- No historical executable contract — phenoForge never had one (verified
  via `git log --all -- src/` on the upstream repo: only the original
  `6a08611` clap scaffold and maintenance commits, no real runner)
- No `--watch` implementation — `--watch` is a documented no-op
  (`FR-OBS-003`) until someone wires `notify` (see the `#[ignore]`
  sentinel in `tests/integration.rs`)
- No `list` / `graph` / `check` / `run` subcommands — clap flat positional
  `task` argument is the only accepted form

## Original audit-closure evidence

- `audit-evidence/phenoforge-closure-20260908/EVIDENCE.md` in the portfolio
- phenoForge `CHANGELOG.md` entry `0.0.0 — Audit closure: truthful scaffold`
- phenoForge `ARCHIVED.md` reconciliation table
- phenoForge `tests/integration.rs` (now `crates/pheno-forge-scaffold/tests/integration.rs`)
