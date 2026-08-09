## AGENTS.md - System Overview

This repo is a Nix Flake-driven dotfiles system built on a repository-owned explicit composition layer in `nix/composition.nix`.

### Architecture
- `flake.nix` assembles native NixOS, nix-darwin, Home Manager, package, check, shell, and formatter outputs through the explicit composition layer.
- Modules implement features; target-first systems/homes compose them via toggles.
- Cross-module integration uses the `liberion` namespace and explicit module arguments.

### Core Principles
1. **Separation of concerns**: Logic in modules, toggles in compositions
2. **Conditional activation**: All config gated by `lib.mkIf cfg.enable`
3. **Namespace isolation**: Use prefix exclusively
4. **Fail-safe defaults**: Features disabled by default, explicit opt-in

### Build / Test
- Full gate: ensure all files tracked, then run `nix flake check`
