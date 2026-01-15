## AGENTS.md - System Overview

This repo is a Nix Flake–driven dotfiles system built atop `snowfall-lib`. Think in layers: reusable modules → system definitions → user compositions.

### Architecture
- `flake.nix` delegates to `snowfall-lib.mkFlake` with `src = ./nix`
- Modules implement features; systems/homes compose them via toggles
- Cross-module integration via explicit namespace

### Core Principles
1. **Separation of concerns**: Logic in modules, toggles in compositions
2. **Conditional activation**: All config gated by `lib.mkIf cfg.enable` 
3. **Namespace isolation**: Use prefix exclusively
4. **Fail-safe defaults**: Features disabled by default, explicit opt-in

### Build / Test
- Full gate: ensure all files tracked, then run `nix flake check`
