# Session Overview

- Goal: add a root `Taskfile.yml` with `build`, `test`, `lint`, and `clean` tasks for the repo.
- Scope: detect the actual language/tooling in the repo, make the task runner work from the repo root, and publish the change.
- Outcome target: root tasks should run the TypeScript package that exists in this checkout and skip cleanly when a target is absent.
