## AGENTS.md - System Overview

Nix flake on [Clan](https://clan.lol) (`clan-core.lib.clan`) for a small fleet of
NixOS and nix-darwin machines with Home Manager. `flake.nix` wires inputs and
outputs; `clan.nix` holds the inventory (machines, tags, service instances).

### Layout
- `identity.nix` - the owner: user name, git identity, fleet SSH keys and port.
- `modules/base/` - imported into every machine of its class (and every home).
- `modules/features/<category>/<name>/` - one feature per directory; importing it
  enables it. How to write one: `modules/AGENTS.md`.
- `modules/profiles/<tag>/` - imported into every machine carrying Clan tag `<tag>`.
- `machines/<name>/` - `configuration.nix` (imports features), optional `home.nix`
  (the owner's Home Manager config there), `hardware/`, `disko.nix`.
- `homes/` - standalone Home Manager configurations (hosts without a managed system).
- `lib/default.nix` - `lib.liberion`: discovery, module helpers, identity.
- `scripts/ci/`, `justfile` - gates and tasks (`just` lists them).
- `sops/`, `vars/` - Clan secrets and generated vars. Never print secret values.

### What a machine runs
Its class base + the profile of each of its tags (`clan.nix`) + the features its
`configuration.nix` and `home.nix` import. That is all plain text: grep for a
feature name to see who uses it.

### Build / Test
- A refactor must not change what machines build:
  - `just drvdiff [ref]` - every machine/home drvPath and every probe (each
    feature imported into a real host, `scripts/ci/probes.nix`) against a git ref;
    no output = pure refactor. A few minutes.
  - `just snap` - machine/home drvPaths only (~30s), for quick iteration.
  - Explain an intended diff with `nix run nixpkgs#nix-diff -- <old.drv> <new.drv>`.
- Full gate: `git add -N .`, then `scripts/ci/check-flake.sh`. Flake evals use
  `path:.` so untracked files count; `.#` needs them tracked.

### Deploy
- NixOS machines: `just deploy <machine>` (clan), then verify on the target.
- This machine: `just switch`.
- Secrets: never craft encrypted blobs by hand; use `clan vars generate <machine>`.
