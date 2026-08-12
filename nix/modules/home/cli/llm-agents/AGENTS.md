# AGENTS.md - LLM agent wrappers

This module owns Home Manager-installed LLM agent launch wrappers.

## Sync contract

- Do not call `~/.config/agents/bin/sync`; that shell trampoline is intentionally gone.
- Nix-generated npm wrappers pass two sync arguments before agent-specific args:
  1. pinned Bun runner (`bunExe`)
  2. sync script path (`~/.config/agents/sync/src/cli.ts`)
- `agent-wrapper.sh` owns launch-time sync behavior:
  - static 60s timeout
  - static 2s termination grace
  - soft-fail warning, then continue launching the agent
- Do not add sync envvar knobs unless explicitly requested; keep policy source-controlled here.

## Wrapper argument shapes

- `agent-wrapper.sh <bun> <sync-script> <npm-launch> <tool> <package> <bin> [agent args...]`
- The wrapper invokes the lib-owned launch script with dist-tag `latest` and a `--version` install-time smoke check:
  `<npm-launch> <tool> <package> <bin> latest --version -- [agent args...]`

## npm launcher library

- `run_npm_package` no longer lives in this module; the npm resolve/install/execute machinery is owned by the lib (`nix/lib/npm`).
- The module consumes only `launchScripts` and `runtimeInputs` from `lib.${namespace}.npm`.
- Cache layout: `~/.cache/npm-tools/<tool>/` with per-version installs under `versions/<version>/` and `current`/`previous` symlinks.
- Pruning keeps `current` and `previous`. A long-running daemon launched from a pruned version dir crashes and is relaunched by KeepAlive onto the newest nightly; that is the intended update path.

## Validation

- `sh -n nix/lib/npm/launch.sh nix/modules/home/cli/llm-agents/agent-wrapper.sh`
- `nix-instantiate --parse nix/modules/home/cli/llm-agents/default.nix nix/lib/npm/default.nix`
