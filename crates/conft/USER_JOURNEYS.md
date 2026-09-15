# Conft — User Journeys

_Traces how a consuming developer moves through the library. Each journey maps to
functional requirements in `typescript/packages/conft/FUNCTIONAL_REQUIREMENTS.md`
and to test coverage in `typescript/packages/conft/src/`._

---

## Journey 1 — Load a typed config from a JSON file

**Actor:** TypeScript application developer
**Trigger:** App startup; config file present on disk
**Success:** Typed config object available; missing required keys throw at load time

| Step | Action | Expected outcome | FR ref | Test file |
|------|--------|-----------------|--------|-----------|
| 1 | Call `FileConfigSource` with a valid JSON path | Source resolves without error | FR-FILE-01 | `index.test.ts` |
| 2 | Pass source to `ConfigManager` | `ConfigManager` merges layers | FR-LAYER-01 | `index.test.ts` |
| 3 | Call `config.get('key')` for existing key | Typed value returned | FR-GET-01 | `index.test.ts` |
| 4 | Call `config.get('missing')` for absent key | Returns `undefined` or throws per schema | FR-GET-02 | `index.test.ts` |

---

## Journey 2 — Override file config with environment variables

**Actor:** DevOps / 12-factor app operator
**Trigger:** App deployed with `APP_*` env vars set
**Success:** Env values take precedence over file values for matching keys

| Step | Action | Expected outcome | FR ref | Test file |
|------|--------|-----------------|--------|-----------|
| 1 | Set `APP_DATABASE_URL` in environment | Env var present | FR-ENV-01 | `index.test.ts` |
| 2 | Layer `EnvConfigSource` on top of file source | Env source wins | FR-LAYER-02 | `index.test.ts` |
| 3 | Call `config.get('database.url')` | Returns env value, not file value | FR-LAYER-03 | `index.test.ts` |

---

## Journey 3 — Validate config with a Zod schema

**Actor:** TypeScript developer adding type-safety guarantees
**Trigger:** App startup with schema defined
**Success:** Invalid config throws `ConfigValidationError` with full path context

| Step | Action | Expected outcome | FR ref | Test file |
|------|--------|-----------------|--------|-----------|
| 1 | Define a Zod schema for the config shape | Schema object created | FR-SCHEMA-01 | `index.test.ts` |
| 2 | Pass schema to config builder | Validation applied at load | FR-SCHEMA-02 | `index.test.ts` |
| 3 | Provide config that violates the schema | `ConfigValidationError` thrown | FR-SCHEMA-03 | `index.test.ts` |
| 4 | Inspect `error.path` | Full key path available | FR-SCHEMA-04 | `index.test.ts` |

---

## Journey 4 — Use immutable config snapshot

**Actor:** Developer who wants a read-only config after initialization
**Trigger:** Boot phase complete; no further mutations wanted
**Success:** `ImmutableConfig` instance returns values; mutation attempts are rejected

| Step | Action | Expected outcome | FR ref | Test file |
|------|--------|-----------------|--------|-----------|
| 1 | Obtain `ImmutableConfig` from builder | Snapshot created | FR-IMM-01 | `index.test.ts` |
| 2 | Call `config.get('key')` | Value returned | FR-IMM-02 | `index.test.ts` |

---

## FR → Test traceability index

| FR category | FR IDs | Covered in |
|-------------|--------|-----------|
| File loading | FR-FILE-01..02 | `src/index.test.ts` (`FileConfigSource` block) |
| Env loading | FR-ENV-01..03 | `src/index.test.ts` (`EnvConfigSource` block) |
| Layering | FR-LAYER-01..03 | `src/index.test.ts` (`ConfigManager` block) |
| Schema validation | FR-SCHEMA-01..04 | `src/index.test.ts` (`ConfigValidationError` block) |
| Immutability | FR-IMM-01..02 | `src/index.test.ts` (`ImmutableConfig` block) |

_Update this table when new FRs or test files are added._
