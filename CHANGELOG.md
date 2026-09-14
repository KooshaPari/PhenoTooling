# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.0] - 2026-09-13

### Added
- macOS `.app` bundle build script (`apps/phinbox-app/build-app.sh`) producing `Phinbox.app` with both `phinbox` and `inbox-helper` binaries.
- Notification beep (`NSSound.beep()`) in inbox-helper when new requests arrive.
- DetailView live countdown pill showing remaining time, turning red <30s.
- `DatePicker` with `pickerKind` support (date/time/datetime).
- `.moveToActiveSpace` on NSWindow collection behavior.

### Changed
- Decomposed all Rust source files to stay under 350 lines (L5).
- Decomposed `DetailView.swift` into `DetailView`, `DetailViewFields`, `DetailViewHelpers`.
- Decomposed `inbox/notify/`, `tui/mod.rs`, `inbox/mod.rs`, `platform/macos/`, `installer/`, `views/html/`, `bin_app/`, `inbox/daemon/http/` into submodules.
- Auto-fixed 164 clippy warnings (267 -> 103 remaining).
- Fixed release pipeline: updated stale `Kooshapari/PhenoTooling` references to `phenotype-tooling`, corrected npm scope to `@kooshapari`.
- Added `tray-native` to `phinbox-app` required-features.

### Fixed
- `DatePicker` styling with proper `@ViewBuilder` for `DatePickerStyle`.
- Stale repository references in install scripts and release workflow.

## [Unreleased]

### Added
- Bootstrap CI (`ci.yml`) + scheduled sync alert (`alert-sync-issues.yml`) as thin callers of the phenoShared reusable Rust CI workflow.
- Dependabot config for cargo (daily) + github-actions (weekly).
- Repository hygiene stubs: `SECURITY.md`, `CONTRIBUTING.md`, `CODEOWNERS`.

### Changed

### Deprecated

### Removed

### Fixed

### Security

[Unreleased]: https://github.com/KooshaPari/phenotype-tooling/compare/HEAD...HEAD
