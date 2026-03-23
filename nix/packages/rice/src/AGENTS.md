# AGENTS.md

## Development

Gate:
- `bun run typecheck`
- `bun test`
- From repo root: `nix build .#rice`
- From repo root: `nix run .#rice -- --help`

Tests and coverage expectations:
- Keep tests exhaustive for routing and action execution paths (success + failure paths).
- Prefer regression tests for every bug fix and behavior change.
- Target is parity with the prior Rust package coverage; if any gap remains, document why in the change notes.

Structure map:
- `default.nix`: generates the external `rice` wrapper during packaging.
- `src/cli.ts`: Bun entrypoint module only.
- `src/core/index.ts`: orchestration and command routing.
- `src/core/cli.ts`: CLI parser and help text.
- `src/core/actions/`: side-effecting workflows and command execution.
- `src/core/tasks/`: immutable task metadata and platform/task definitions.
- `src/runtime/`: runtime boundary helpers.
- `test/`: parser/actions/routing tests and shared test support.
