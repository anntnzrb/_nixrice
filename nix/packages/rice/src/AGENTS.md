# AGENTS.md

## Development

Gate:
- `cargo fmt --check`
- `cargo clippy --all-targets --all-features -- -D warnings`
- `cargo test`
- `cargo doc --no-deps`
- From repo root: `nix run .#rice -- --help`

Tests and coverage expectations:
- Keep tests exhaustive for routing and action execution paths (success + failure paths).
- Prefer regression tests for every bug fix and behavior change.
- Target is 100% coverage for the Rust package; if any gap remains, document why in the change notes.

Structure map:
- `main.rs`: binary entrypoint only.
- `lib.rs`: orchestration and command routing.
- `cli.rs`: CLI parser and command tree.
- `actions/`: side-effecting workflows and command execution.
- `tasks/`: immutable task metadata and platform/task definitions.
- `unit_tests/`: parser/actions/routing tests and shared test support.
