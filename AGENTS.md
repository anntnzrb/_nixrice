## AGENTS.md

Nix flake on [Clan](https://clan.lol) (`clan-core.lib.clan`) for a fleet of
NixOS and nix-darwin machines with Home Manager. This is the only AGENTS.md.
It describes structure and rules, never current state: which machines exist,
their tags, what they import, versions and counts live in the code. Read the
code for those; do not copy them here.

### Layout
```
identity.nix                 owner: user name, git identity, fleet SSH keys and port
clan.nix                     inventory: machines + tags, service instances
flake.nix                    inputs, outputs, dev shell, pre-commit hooks
lib/default.nix              lib.liberion: discovery, machineModule, module helpers, identity
modules/
├── base/<name>/             always imported (every machine of the class / every home)
├── features/<category>/<name>/   opt-in, imported by machines, profiles or other features
├── profiles/<tag>/          imported into machines carrying Clan tag <tag>
└── services/<name>/         in-repo Clan services (_class = "clan.service")
machines/<name>/             configuration.nix, optional home.nix, hardware/, readme.md
homes/                       standalone Home Manager configs (hosts without a managed system)
overlays/                    the flake overlay
tests/                       `just test`; probe-errors.txt for `just probes`
scripts/ci/                  everything behind the `just` gates and CI
justfile                     tasks (`just` lists them)
.github/                     workflows, Dependabot
.agents/setup, .agents/resume   Amp orb (cloud sandbox) setup
sops/, vars/                 Clan secrets and generated vars; never print values
```

### Finding things
- Machines, their class and tags: `clan.nix` `inventory.machines`. Every
  directory under `machines/` is a machine
- What a machine runs: its class base + the profile of each of its tags +
  Clan service instances targeting it or its tags (`clan.nix`
  `inventory.instances`) + the features its `configuration.nix` and `home.nix`
  import. All plain text: grep a feature name to see who uses it
- What a tag does: `modules/profiles/<tag>/`. No directory = descriptive tag
- Available features: the directories under `modules/features/`
- A `liberion.*` option: grep `options.liberion.<path>`

### Where to edit
- A program for the owner: `modules/features/<category>/<name>/home.nix`
- System config: same directory, `nixos.nix`, `darwin.nix`, or `system.nix` for both
- Enable a feature on one machine: `imports` in `machines/<name>/configuration.nix` or `home.nix`
- Enable it in every home / every machine: `modules/base/common/home.nix` / a `modules/base/<name>/`
- What a trait means: `modules/profiles/<tag>/`
- Add a machine or change its tags: `clan.nix` `inventory.machines` + `machines/<name>/`
- Fleet services (sshd, users, remote builders): `clan.nix` `inventory.instances`; in-repo ones in `modules/services/`
- User, git identity, SSH keys, SSH port: `identity.nix`
- Binary caches: `liberion.nix.caches` (`modules/base/nix/`)
- darwin GUI apps as Homebrew casks: `liberion.homebrew.apps`
- CI: `.github/workflows/`, `scripts/ci/`

### Tags
Tags are traits; profiles never import each other. Clan adds `all`, `nixos`,
`darwin` automatically (never list them by hand). Some tag names also carry
meaning outside their profile:
- `server`: fleet `sshd` and `users` instances target it; only tag a machine
  `server` after `clan vars` exist for it
- `archived`: retired machine kept as history; excluded from CI builds and
  Cachix (`scripts/ci/targets.nix`) and from fleet SSH peer lists
  (`network/sshd`). Its profile pins a fixed `system.stateVersion` because
  those machines predate Clan; the rest use the generated state-version var.
  `clan machines update` without arguments skips them (`requireExplicitUpdate`)

### Writing modules
Class files: `nixos.nix`, `darwin.nix`, `home.nix`, `system.nix` (NixOS and
nix-darwin alike). `lib/default.nix` discovers them and exports every feature
by directory name as `self.{nixos,darwin,home}Modules.<name>`. Other files in
a directory are helpers, imported explicitly; paths containing `/_` are
ignored. Directory names are unique across features and profiles.

**Importing a feature is enabling it** - there are no `enable` toggles:

```nix
# modules/features/cli/btop/home.nix
{
  programs.btop = {
    enable = true;
    settings.vim_keys = true;
  };
}
```

Then `imports = with inputs.self.homeModules; [ btop ];` wherever it is
wanted. A feature with both a system file and `home.nix` also hands the home
part to the owner's Home Manager configuration when a machine imports it.

Knobs a machine may tune are ordinary options under `liberion.<category>.<name>`:

```nix
{ lib, config, ... }:
let
  cfg = config.liberion.cli.ssh;
in
{
  options.liberion.cli.ssh.identityFile = lib.liberion.module.mkOpt' lib.types.str "~/.ssh/id_ed25519";
  config.programs.ssh.settings."*".IdentityFile = cfg.identityFile;
}
```

Helpers: `lib.liberion.module.{mkOpt', mkOptEnabled', mkOptDisabled'}`,
`lib.liberion.identity`. Prefer precise types (`enum`, `package`, `port`) over `str`.

In-repo Clan services: `modules/services/<name>/default.nix`
(`_class = "clan.service"`), registered in `clan.nix` as
`modules.<name> = ./modules/services/<name>;` and instantiated under
`inventory.instances.<name>` with `module = { input = "self"; name = "<name>"; };`.

### Gotchas
- Import order is merge order for list options. Harmless for package lists,
  but PATH (`home.sessionPath`) and script snippets are order-sensitive: pin
  them with `lib.mkBefore`/`lib.mkAfter`, never rely on import order
- darwin Nix: Determinate Nix owns `/etc/nix/nix.conf` and GC, so
  `nix.enable = false`. Daemon options go in `determinateNix.customSettings`,
  never `nix.settings`. `liberion.nix.caches` feeds whichever applies
- `modules/base/nixpkgs/` sets `nixpkgs.config`/overlays only when
  `nixpkgs.pkgs` is unset: Clan injects its own `pkgsFor` for vars
- `clan.core.enableRecommendedDefaults` is off in base; profiles opt in
- Boot loaders live in `features/boot/`; base only sets baselines
- SSH: `cli/ssh` is the personal `~/.ssh/config`. Fleet `Host` blocks come from
  `network/sshd` into `/etc/ssh/ssh_config` (read after the user file), built
  from Clan inventory metadata without evaluating peers. The fleet port
  (`identity.nix`) is not 22 because tailnet 22 is Tailscale SSH, which lacks
  Clan host keys; everything SSH-related reads it from `lib.liberion.identity`
- `desktop/session` exports `liberion.desktop.session.apps.*` as environment
  variables that window manager configs read; WM features import `session`
- `network/dhcp` and NetworkManager are mutually exclusive (NM forces
  `networking.useDHCP = false`)
- `hardware/disko-xfs` wipes its target device on install; use `/dev/disk/by-id`
- Files deployed verbatim (scripts, WM configs) are compared by content: any
  edit, comments included, shows up in `just report`

### darwin patterns
- launchd opens `StandardOutPath`/`StandardErrorPath` eagerly: create
  state/log dirs in a `home.activation` step first
- launchd agents need executables that survive generations: stage them at a
  stable path instead of a store path. Launch GUI apps via `/usr/bin/open -a`
- Wrap store executables in `/bin/wait4path /nix/store` (nix-darwin `command`)
  when a daemon can start before the store volume mounts
- `system.defaults` overwrites whole preference domains; change single keys
  with `defaults write` in `system.activationScripts.postActivation`
- Stock sshd socket activation is fixed to port 22, so `network/sshd` runs its
  own launchd daemon for other ports
- Self-updating apps or ones with privileged helpers go through Homebrew
  casks (`liberion.homebrew.apps`), not the store
- HM's Firefox wrapper can't wrap `firefox-bin`: set `programs.firefox.package =
  null` and install the package separately

### Tools (run from the repo root; `just` lists them)
Evaluation reads the working tree through `path:.`, so new files count without
`git add`. None of these touch a machine; only `just fmt` edits files.

- `just test`: run `tests/` (lib discovery + every machine keeps fleet SSH access); fast
- `just report [ref]`: what your change does to each machine and home (packages, files, services, users, env, PATH order) versus `ref`; empty = no behaviour change; minutes
- `just snap`: print every machine/home drvPath, a quick "does it still evaluate"; fast
- `just probes`: import every feature into a real host; fails if the set that does not evaluate differs from `tests/probe-errors.txt` (shardable: `PROBE_SHARD`/`PROBE_SHARDS`); slow
- `just drvdiff [ref]`: prove a pure refactor, machine, home **and** per-feature drvPaths identical to `ref` (the only check covering features no machine uses); slow
- `just check`: the CI gate, flake-checker, evaluate everything, formatting, lint hooks, flake checks incl. tests; minutes
- `just fmt`: format with the repo's formatter; use this, not `nixpkgs#nixfmt`; fast
- `just build-all`: build every machine and home this platform can build, nothing is activated; very slow, needs disk

- Before handing off any change: `just report` (state the result), then `just check`
- A refactor that should not change behaviour: `just report` must be empty; for
  changes to features no machine imports, also `just drvdiff`. Explain any drvPath
  diff with `nix run nixpkgs#nix-diff -- <old.drv> <new.drv>`
- `tests/probe-errors.txt` lists modules expected not to evaluate on their probe
  host (`scripts/ci/probes.nix`): genuine platform mismatches only, e.g. a
  Linux-only home feature probed on darwin. Add a line when your feature is one
- Lint hooks (`flake.nix` pre-commit) run on `git commit` in the dev shell
  (`nix develop`) and in `just check`
- The synthetic probe host is its own Clan instance rooted at `scripts/ci/`, so
  no real machine, tag or profile leaks into probes. `just report`
  fingerprints repo files by content, so pure moves are invisible to it

### Not for agents
- `just switch`, `build`, `boot`, `home`, `deploy`: the owner deploys
- `just update`: flake inputs are updated by Dependabot PRs
- `just clean`, `optimise`, `repair`, `bin/nix-install.sh`: host maintenance
- Do not commit or push unless asked. Never print values from `sops/` or `vars/`;
  generate secrets with `clan vars generate <machine>`, never by hand

### CI (`.github/workflows/`)
- `ci.yml`: `just check` (Linux; it evaluates darwin too), sharded
  `just probes`, and on PRs the `just report` summary against the base branch
- `build.yml`: `scripts/ci/build-plan.sh` lists the targets from
  `scripts/ci/targets.nix` missing from the Cachix cache; each builds on its
  own runner and is pushed. Nothing uncached = nothing built. Dev shells are
  targets too so sandboxes substitute `clan-cli`
- `dependabot.yml` + `auto-merge.yml`: grouped update PRs that merge themselves
  once the required checks pass, so updates land already built and cached.
  `auto-merge.yml` runs on `pull_request_target` and never checks out PR code
  (write token + untrusted content)
- `flake-checker` runs without `--check-outdated`: nixpkgs freshness belongs to
  Dependabot, not unrelated PRs
- `scripts/ci/*.sh` run under dash on Ubuntu runners: no `pipefail`, so capture
  `nix eval` into a variable before piping; no `sort -s`. Scripts holding temp
  state define `cleanup()` then source `scripts/ci/cleanup.sh` (traps EXIT and
  re-raises HUP/INT/TERM, which dash would skip)

### Conventions
- Skills: load nix and clan skills before writing Nix
- Comments: none by default. Structural knowledge goes in this file; a comment
  stays only where removing the line it guards would silently break something
  (upstream bug refs, opaque IDs, magic values)
- This file holds no state. If an edit here would need updating when a machine,
  tag, import, version or count changes, point to the source file instead
- `flake.nix`: `nixpkgs` follows `clan-core/nixpkgs`; clan-core is a
  `git+https://` URL so Dependabot can bump it; the dev shell has no LSPs
  (editors bring their own)
- After editing `.agents/setup`, stale Amp snapshots stay until
  `amp projects snapshots delete anntnzrb/rice`
