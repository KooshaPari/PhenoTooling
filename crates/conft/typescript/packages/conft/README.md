# phenotype-config-ts

TypeScript **configuration management** with **Zod** validation, hexagonal ports (`ConfigSource`), and adapters for **file** and **environment** sources.

## Package

- **npm name**: `@phenotype/config-ts`
- **Stack**: TypeScript, Zod, Vitest

## Layout

| Path | Role |
|------|------|
| `src/domain/` | Config domain model |
| `src/ports/` | `ConfigSource` port |
| `src/adapters/` | File + env adapters |

## Scripts

```bash
bun install --frozen-lockfile
bun run build
bun run test
bun run typecheck
bun run check
```

## Related

- `phenotype-config` — Rust / org-wide config hub
- `adr/ADR-001-architecture.md` — architecture notes

## License

MIT
