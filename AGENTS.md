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

### Tools (run from the repo root; `just` lists them)
Evaluation reads the working tree through `path:.`, so new files count without
`git add`. None of these touch a machine; only `just fmt` edits files.

| Command | Use it to | Time |
|---|---|---|
| `just test` | run `tests/` (lib discovery + every machine keeps fleet SSH access) | seconds |
| `just report [ref]` | see what your change does to each machine and home (packages, files, services, users, env, PATH order) versus `ref`; empty = no behaviour change | ~1 min |
| `just snap` | print every machine/home drvPath; quick "does it still evaluate" | ~30 s |
| `just probes` | import every feature into a real host; fails if the set that does not evaluate differs from `tests/probe-errors.txt` (CI splits it over 4 runners: `PROBE_SHARD`/`PROBE_SHARDS`) | ~5 min |
| `just drvdiff [ref]` | prove a pure refactor: machine, home **and** per-feature drvPaths identical to `ref` (the only check covering features no machine uses) | ~8 min |
| `just check` | the CI gate: flake-checker, evaluate everything, formatting, lint hooks, flake checks incl. tests | ~3 min |
| `just fmt` | format tracked Nix files (nixfmt) | seconds |
| `just build-all` | build every machine and home this platform can build (what `build.yml` does; nothing is activated) | long, needs disk |

- Before handing off any change: `just report` (state the result), then `just check`.
- A refactor that should not change behaviour: `just report` must be empty; for
  changes to features no machine imports, also `just drvdiff`. Explain any drvPath
  diff with `nix run nixpkgs#nix-diff -- <old.drv> <new.drv>`.
- Adding a feature that cannot evaluate on a probe host (a Linux-only home
  feature probed on beirut, say): add its line to `tests/probe-errors.txt`.
- Lint hooks (nixfmt, deadnix, statix, shellcheck, shfmt, actionlint) run on
  `git commit` in the dev shell (`nix develop`) and in `just check`.

### Not for agents
- `just switch`, `just build`, `just home`, `just deploy`: the owner deploys.
- `just update`: flake inputs are updated by Dependabot PRs (`.github/dependabot.yml`).
- `just clean`, `just optimise`, `just repair`, `bin/nix-install.sh`: host maintenance.
- Do not commit or push unless asked. Never print values from `sops/` or `vars/`;
  generate secrets with `clan vars generate <machine>`, never by hand.

### CI (`.github/workflows/`)
- `ci.yml` (PRs, pushes to dev): `just check` (Linux; it evaluates darwin too),
  `just probes` split over 8 runners, and on PRs the `just report` summary
  against the base branch (job summary).
- `build.yml` (Dependabot flake PRs, pushes to dev touching Nix code, weekly,
  manual): `scripts/ci/build-plan.sh` lists the machines and homes missing from
  the `anntnzrb` Cachix cache (`scripts/ci/targets.nix`); each builds on its
  own runner and is pushed. Nothing uncached = nothing built. `builds` is
  required on Dependabot PRs, so updates land already built and cached.
- `dependabot.yml` + `auto-merge.yml`: one grouped PR for all flake inputs and one for
  GitHub Actions, weekly; each merges itself once the required checks (`check`, `probes`, `builds`)
  pass. The PR job summary carries `just report`.

