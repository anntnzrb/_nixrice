## AGENTS.md - System Overview

This repo is a Nix Flake-driven dotfiles system built on [Clan](https://clan.lol)
(`clan-core.lib.clan`): `flake.nix` wires inputs and outputs, `clan.nix` holds the
fleet inventory (machines, tags, service instances).

### Layout
- `machines/<name>/` - one directory per machine, auto-discovered by Clan
  (`configuration.nix`, optional `disko.nix`, `hardware/`, `home.nix`, readme).
- `modules/` - feature modules (`nixos/`, `darwin/`, `home/`, `shared/`) and their
  entrypoints (`default.nix`, `darwin.nix`, `home.nix`, `home-manager.nix`).
- `homes/` - standalone Home Manager configurations (hosts without a managed system).
- `lib/` - repository helpers exposed as `lib.liberion.*`.
- `overlays/` - package overlay.
- `justfile` - day-to-day tasks (build, switch, deploy, update, check); run `just` to list them.
- `sops/`, `vars/` - Clan secrets and generated vars. Never print secret values.

### Architecture
- Modules implement features; machines and homes compose them via toggles.
- Cross-module integration uses the `liberion` namespace and explicit module arguments
  (`lib`, `inputs`, `self`, `namespace`).
- Machines: `nixosConfigurations.<name>` / `darwinConfigurations.<name>`; hosted homes
  live under `…config.home-manager.users.<user>`.

### Core Principles
1. **Separation of concerns**: Logic in modules, toggles in compositions
2. **Conditional activation**: All config gated by `lib.mkIf cfg.enable`
3. **Namespace isolation**: Use prefix exclusively
4. **Fail-safe defaults**: Features disabled by default, explicit opt-in

### Build / Test
- Full gate: ensure all files tracked (`git add -N .`), then run `scripts/ci/check-flake.sh`

### Deploy
- NixOS machines: `just deploy <machine>` (clan, as `annt@<machine>:2222`), then verify on the target.
- This machine: `just switch` (darwin-rebuild or nixos-rebuild, host from `hostname -s`).
- Before deploying, evaluate: `nix eval .#<nixos|darwin>Configurations.<machine>.config.system.build.toplevel.drvPath`.
- Secrets: never craft encrypted blobs by hand; use `clan vars generate <machine>` and let Clan own the age/sops lifecycle.
