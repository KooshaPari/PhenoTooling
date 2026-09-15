# Eventra Provenance

## Source Repository

- **Repository**: [KooshaPari/zz-merge-unk-Eventra](https://github.com/KooshaPari/zz-merge-unk-Eventra)
- **Commit**: `6ca16520d89fde182cbd9dda3c277d5d579f96d5`
- **Date absorbed**: 2026-09-15
- **Package name**: `eventkit`
- **License**: MIT OR Apache-2.0

## What Was Migrated

The top-level `src/` directory from the Eventra repository, which contains the core
event-driven architecture framework with CQRS and Event Sourcing patterns:

- `src/adapters/` - Event bus and event store adapters
- `src/application/` - Command handlers, event bus, and projections
- `src/domain/` - Aggregates, commands, events, and errors
- `src/infrastructure/` - Error handling and metrics
- `src/workflow/` - Workflow orchestration
- `src/lib.rs` - Library root

## Not Migrated

The `rust/` sub-workspace in the source repository contained additional crates
(`phenotype-event-sourcing`, `eventkit-obs`, `phenotype-event-contracts`,
`phenotype-error-core`, `phenotype-event-bus`). These were not migrated as part
of this absorption. They may exist independently or be absorbed in a future pass.

## Original Dependencies

- `serde` 1.0 (with derive)
- `serde_json` 1.0
- `thiserror` 1.0
- `anyhow` 1.0
- `async-trait` 0.1
- `parking_lot` 0.12
- `chrono` 0.4 (with serde)
- `uuid` 1.0 (with v4, serde)
