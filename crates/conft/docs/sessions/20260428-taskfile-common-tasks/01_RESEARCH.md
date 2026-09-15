# Research

- Repo contents show a TypeScript package at `typescript/packages/conft/` with `package.json`, `src/`, `docs/`, and `bun.lock`.
- The repo root had an existing `Taskfile.yml` that pointed at stale Rust paths and needed replacement with root-level detection logic.
- The TypeScript package had no ESLint config checked in, so the root `lint` task needs to skip cleanly instead of hard-failing.
- `task build` initially failed on a duplicate `ConfigValidationError` export and then on `zod` declaration resolution; both were fixed so the build task succeeds.
