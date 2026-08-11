# AGENTS.md - LLM agent wrappers

This module owns Home Manager-installed LLM agent launch wrappers.

## Sync contract

- Do not call `~/.config/agents/bin/sync`; that shell trampoline is intentionally gone.
- Nix-generated npm wrappers pass two sync arguments before agent-specific args:
  1. pinned Bun runner (`bunExe`)
  2. sync script path (`~/.config/agents/sync/src/cli.ts`)
- `agent-wrapper-common.sh` owns launch-time sync behavior:
  - static 60s timeout
  - static 2s termination grace
  - soft-fail warning, then continue launching the agent
- Do not add sync envvar knobs unless explicitly requested; keep policy source-controlled here.

## Wrapper argument shapes

- `npm-agent-wrapper.sh <bun> <sync-script> <tool> <package> <bin> [agent args...]`
- `run_npm_package` in `agent-wrapper-common.sh` accepts:
  `<tool> <package> <bin> <dist-tag> -- [agent args...]`
- The npm wrapper invokes the common resolver with dist-tag `latest`.

## Validation

- `sh -n agent-wrapper-common.sh npm-agent-wrapper.sh`
- `nix-instantiate --parse default.nix`

