# Requirements Traceability

Traceability coverage is defined as requirements with an explicit implementation or gap
evidence path divided by requirements declared in `FUNCTIONAL_REQUIREMENTS.md`.

| Requirement | Status | Evidence | Current boundary |
|---|---|---|---|
| FR-SCHEMA-001 | Partial | `src/domain/config.ts` | Value schemas exist; loaded aggregate schema injection is not implemented. |
| FR-SCHEMA-002 | Partial | `src/index.test.ts` | Typed contextual errors exist; aggregate failing-field reporting is not implemented. |
| FR-SCHEMA-003 | Verified | `src/domain/config.ts` + `bun run typecheck` | `ConfigValue` is inferred from its Zod schema under strict TypeScript. |
| FR-SRC-001 | Partial | `src/adapters/file-adapter.test.ts` | JSON is tested; YAML and TOML remain unimplemented. |
| FR-SRC-002 | Verified | `src/adapters/env-adapter.test.ts` | Prefix mapping and typed coercion are executable tests. |
| FR-SRC-003 | Verified | `src/services/config-manager.test.ts` | Source composition and priority order are executable tests. |
| FR-LAYER-001 | Verified | `src/services/config-manager.test.ts` | Lower-priority base values and higher-priority overrides are tested. |
| FR-LAYER-002 | Gap | `adr/ADR-003-deep-merge.md` | Current manager replaces nested values; deep merge remains a planned decision. |
| FR-LAYER-003 | Gap | `src/domain/secret.test.ts` | In-memory redaction exists; environment-reference resolution is not implemented. |
| FR-HEX-001 | Verified | `src/ports/config-source.ts` | The asynchronous `ConfigSource` port is explicit and typechecked. |
| FR-HEX-002 | Verified | `src/services/config-manager.ts` | `ConfigManager` depends on the port abstraction. |
| FR-HEX-003 | Verified | `src/adapters/file-adapter.ts`, `src/adapters/env-adapter.ts` | Infrastructure adapters are isolated from domain code. |

Exact totals:

- Traceability: **12/12 = 100%**
- Verified implementation: **7/12 = 58.33%**
- Partial implementation: **3/12 = 25%**
- Explicit gaps: **2/12 = 16.67%**

Traceability is not represented as requirement satisfaction. The executable traceability test
fails if a requirement is added, removed, duplicated, or points to missing evidence.
