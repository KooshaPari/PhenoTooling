# Provenance: PhenoJourneys Rust CLI

**Source repository:** `KooshaPari/zz-merge-unk-PhenoJourneys`
**Absorbed into:** `KooshaPari/phenotype-tooling`
**Date:** 2026-09-15
**Absorbed by:** Jcode agent (automated)

## What was absorbed

Rust CLI crates and binary from the PhenoJourneys journey harness:

| Source path | Destination path | Description |
|---|---|---|
| `crates/phenotype-journey-core/` | `crates/phenotype-journey-core/` | Core journey types and logic |
| `crates/klipdot-capture/` | `crates/klipdot-capture/` | Klipdot capture utilities |
| `crates/phenotype-journeys-observability/` | `crates/phenotype-journeys-observability/` | Journey observability/tracing |
| `bin/phenotype-journey/` | `bin/phenotype-journey/` | CLI binary entry point |

## What was NOT absorbed (goes to phenoDesign)

Vue/JS/Playwright/Remotion code went to `KooshaPari/phenoDesign`:

- `npm/journey-viewer/` — Vue components (ShotGallery, JourneyViewer, etc.)
- `npm/playwright-record/` — Playwright recorder (TypeScript)
- `npm/journey-playwright/` — Playwright helper (TypeScript)
- `remotion/doc-embeds/` — Remotion/React doc embeds

## License

Original code is Apache-2.0. phenotype-tooling uses MIT. Absorbed code retains its original license headers where present.
