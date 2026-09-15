# tasken

Universal task execution framework with scheduling, workflow orchestration, and plugin support.

Absorbed from [zz-Tasken](https://github.com/KooshaPari/zz-Tasken) into the phenotype-tooling workspace.

## Features

- Task lifecycle management (create, run, cancel, retry)
- Workflow orchestration with DAG-based dependency resolution
- Cron-based scheduling
- TOML/YAML recipe system with imports and conditions
- Plugin system with rate limiting and observability
- File watching for automatic task triggers
- Persistent caching and storage (in-memory and JSON file)
- Structured error handling and metrics

## Usage

```bash
taskkit create "my-task" -- echo "hello"
taskkit run <task-id>
taskkit list
taskkit workflow run <recipe-path>
```

## Architecture

Hexagonal architecture with clear layer separation:

- **domain/** - Task models, workflows, recipes, scheduling, plugins
- **application/** - Services, commands, queries, visualization
- **adapters/** - CLI, file storage, memory storage, plugins
- **infrastructure/** - Metrics, caching, OpenTelemetry

## License

MIT OR Apache-2.0
