## AGENTS.md - System Overview

This repo is a Nix Flake-driven dotfiles system built on [Clan](https://clan.lol)
(`clan-core.lib.clan`): `flake.nix` wires inputs and outputs, `clan.nix` holds the
fleet inventory (machines, tags, service instances).

### Layout
- `machines/<name>/` - one directory per machine, auto-discovered by Clan
  (`configuration.nix`, optional `disko.nix`, `hardware/`, `home.nix`, readme).
- `modules/` - feature modules (`nixos/`, `darwin/`, `home/`, `shared/`), their
  entrypoints (`default.nix`, `darwin.nix`, `home.nix`, `home-manager.nix`) and the
  toggle factory `toggle.nix`. How to write one: `modules/AGENTS.md`.
- `homes/` - standalone Home Manager configurations (hosts without a managed system).
- `lib/default.nix` - repository helpers exposed as `lib.liberion.*`.
- `overlays/` - package overlay.
- `scripts/ci/` - CI gate plus the regression tools below.
- `justfile` - day-to-day tasks; run `just` to list them.
- `sops/`, `vars/` - Clan secrets and generated vars. Never print secret values.

### Architecture
- Modules implement features behind `liberion.<path>.enable`; machines and homes
  compose them via toggles. Option paths are written literally (`liberion.cli.git`),
  so `git grep 'cli.git'` finds declaration and setters alike.
- `clan.nix` gives every machine the module set of its class
  (`self.{nixos,darwin}Modules.default`); machine files hold only machine specifics.
- Liberion homes import `modules/home.nix` (`machines/*/home.nix`, `homes/*.nix`).
- Machines: `nixosConfigurations.<name>` / `darwinConfigurations.<name>`; hosted homes
  live under `…config.home-manager.users.<user>`.

### Core Principles
1. **Separation of concerns**: Logic in modules, toggles in compositions
2. **Conditional activation**: Feature config gated by its `enable`
3. **Namespace isolation**: Every option lives under `liberion.`
4. **Fail-safe defaults**: Features disabled by default, explicit opt-in

### Build / Test
- A refactor must not change what machines build. Prove it:
  - `just drvdiff [ref]` - diffs every machine/home drvPath *and* every probe
    against a git ref (default `HEAD`); no output means a pure refactor.
    Probes switch on each toggle no host enables, over a real host, so unused
    modules are checked too (`scripts/ci/probes.nix`). Takes a few minutes.
  - `just snap` - machine/home drvPaths only (~30s), for quick iteration.
  - Explain an intended diff with `nix run nixpkgs#nix-diff -- <old.drv> <new.drv>`.
- `just enabled <machine>` - the liberion toggles a machine turns on (grep cannot
  tell you this: suites enable toggles indirectly).
- Full gate: ensure all files tracked (`git add -N .`), then run `scripts/ci/check-flake.sh`.
  Flake evals use `path:.` so untracked files are seen; `.#` needs them tracked.

### Deploy
- NixOS machines: `just deploy <machine>` (clan, as `annt@<machine>:2222`), then verify on the target.
- This machine: `just switch` (darwin-rebuild or nixos-rebuild, host from `hostname -s`).
- Before deploying, evaluate: `nix eval .#<nixos|darwin>Configurations.<machine>.config.system.build.toplevel.drvPath`.
- Secrets: never craft encrypted blobs by hand; use `clan vars generate <machine>` and let Clan own the age/sops lifecycle.
