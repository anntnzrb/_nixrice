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
machines/<name>/             configuration.nix, optional home.nix, facter.json or hardware/, optional disk.nix (disko), readme.md
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
- Add a machine or change its tags: `clan.nix` `inventory.machines` + `machines/<name>/`;
  installing it is the "Installing a NixOS machine" section below
- Fleet services (sshd, users, remote builders, wifi, internet): `clan.nix`
  `inventory.instances`; in-repo ones in `modules/services/`
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
  (`network/sshd`). On NixOS its profile pins a fixed `system.stateVersion`
  because those machines predate Clan; the rest use the generated
  state-version var.
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

Helpers live in `lib/default.nix` (`lib.liberion`); read it before writing a
module, its exports are the list, not this file. Prefer precise types (`enum`,
`package`, `port`) over `str`.

Shared code goes in `lib.liberion`, not in copies. Before writing a block, grep
`modules/` for the same shape: launchd agent, activation snippet, `defaults`
write, `launchctl asuser`, option boilerplate. A shape already in a second
module becomes a helper in `lib/default.nix` (pure functions get a case in
`tests/default.nix` `libFailures`) and every copy moves to it in the same
change. Shell scripts read from a file take the helper's output as an argument
instead of re-typing it. Values that come from `identity.nix`, another option
or a package are referenced, never hardcoded.

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
- Hardware on NixOS machines with `facter.json` comes from nixos-facter (Clan
  wires it). Don't hand-write kernel modules, microcode or `hostPlatform` there;
  switch off unwanted detections with `hardware.facter.detected.<x>.enable = false`.
  Regenerate with `clan machines update-hardware-config <m> --backend nixos-facter`
- Files deployed verbatim (scripts, WM configs) are compared by content: any
  edit, comments included, shows up in `just report`
- A machine home that must skip `modules/base` home (headless servers) is a
  `_home.nix` the machine imports itself: `machineModule` adds the base home to
  any `home.nix`, and `/_` paths are invisible to discovery
- Evaluate attributes with `nix eval path:.#nixosConfigurations.<m>.config.<opt>`
  (`darwinConfigurations`, `homeConfigurations."<user>@<host>"`, inventory under
  `clan.inventory`); `path:.` reads the working tree without the dirty-tree
  warning. Don't guess other flake attributes: `nix flake show path:.` lists them
- A machine's `clan.nix` entry and `machines/<name>/` describe the target
  state; its `readme.md` says when the hardware runs something else today

### darwin patterns
- launchd opens `StandardOutPath`/`StandardErrorPath` eagerly: create
  state/log dirs in a `home.activation` step first
- launchd agents need executables that survive generations: stage them at a
  stable path instead of a store path. Launch GUI apps via `/usr/bin/open -a`
- Wrap store executables in `/bin/wait4path /nix/store` (nix-darwin `command`)
  when a daemon can start before the store volume mounts
- Removing a feature must undo what it wrote. `modules/base/reconcile`
  records what the configuration owns and, on the next switch, deletes what
  no module claims anymore. Preferences go through `system.defaults`
  (`CustomUserPreferences` for app domains) or
  `liberion.darwin.defaults.currentHost` (ByHost), which are tracked
  automatically. Anything an activation script writes itself must be claimed
  in `liberion.darwin.owned.defaults` (a key, or a nested `path` inside one)
  or `liberion.darwin.owned.files`. Unreadable domains are kept and retried.
  A new nix-darwin `system.defaults` scope fails evaluation until it is mapped.
  Only what the configuration claimed is ever removed: apps, preferences and
  grants the owner set up by hand are never touched. A failing reconcile warns
  and retries on the next switch instead of aborting activation
- Privacy grants (TCC) cannot be given declaratively: macOS requires MDM, and
  macOS 27 removed silent Accessibility grants even there. Claim the grants a
  feature needs in `liberion.darwin.owned.privacy` so removing it revokes them
  (`tccutil reset`); the owner grants them once per machine
- Stock sshd socket activation is fixed to port 22, so `network/sshd` runs its
  own launchd daemon for other ports
- GUI apps come from Homebrew casks (`liberion.homebrew.apps`) or a nixpkgs
  `-bin` package that ships the vendor's `.app`, never a nixpkgs source build.
  TCC binds a grant to the code signature: a vendor-signed app keeps it across
  updates, an ad-hoc signed store build loses it on every rebuild. Check with
  `codesign -dr - <App>.app`: `cdhash` in the requirement means ad-hoc
- HM's Firefox wrapper can't wrap `firefox-bin`: set `programs.firefox.package =
  null` and install the package separately

### Tools (run from the repo root; `just` lists them)
Evaluation reads the working tree through `path:.`, so new files count without
`git add`. None of these touch a machine; only `just fmt` edits files.

- `just test`: run `tests/` (lib discovery + every machine keeps fleet SSH access); fast
- `just report [ref]`: what your change does to each machine and home (packages, files, services, users, env, PATH order) versus `ref`; empty = no behaviour change; minutes
- `just snap`: print every machine/home drvPath, a quick "does it still evaluate"; fast
- `just probes`: locally import every feature into a real host in one unsharded `nix-eval-jobs` run; fails if the set that does not evaluate differs from `tests/probe-errors.txt` (`PROBE_WORKERS`, default one per core; `PROBE_MAX_MEMORY`); slow
- `just drvdiff [ref]`: prove a pure refactor, machine, home **and** per-feature drvPaths identical to `ref` (the only check covering features no machine uses); slow
- `just check`: the CI gate, flake-checker, one `nix flake check` (formatting, lint hooks, tests; `--all-systems` on Linux), `clan vars check`; minutes
- `just fmt`: treefmt (`flake.nix`: nixfmt, shfmt, just); use this, not `nixpkgs#nixfmt`; fast
- `just build-all`: build every machine and home this platform can build, nothing is activated; very slow, needs disk

- Before handing off any change: `just report` (state the result), then `just check`
- A refactor that should not change behaviour: `just report` must be empty; for
  changes to features no machine imports, also `just drvdiff`. Explain any drvPath
  diff with `nix run nixpkgs#nix-diff -- <old.drv> <new.drv>`
- `tests/probe-errors.txt` lists modules expected not to evaluate on their probe
  host (`scripts/ci/probes.nix`): genuine platform mismatches only, e.g. a
  Linux-only home feature probed on darwin. Add a line when your feature is one
- Lint hooks (`flake.nix` pre-commit: treefmt, deadnix, statix, shellcheck,
  actionlint, zizmor) run on `git commit` in the dev shell (`nix develop`) and in `just check`
- The synthetic probe hosts (one Linux, one Darwin) are their own Clan instance
  rooted at `scripts/ci/`, so no real machine, tag, profile or feature leaks
  into probes. `just report`
  fingerprints repo files by content, so pure moves are invisible to it

### Installing a NixOS machine
Owner-run (it wipes a disk), but an agent prepares the repo and the commands.
Source: `clan-core` `pkgs/clan-cli/clan_lib/machines/install.py`,
`docs/src/getting-started/getting-started-physical.md`, nixos-anywhere `src/nixos-anywhere.sh`.

1. Repo: `inventory.machines.<m>` with tags, `machines/<m>/configuration.nix`,
   a `disk.nix` (or `hardware/disko-xfs`) whose device is a `/dev/disk/by-id/`
   path matched by serial, `readme.md`. Tag `server` only after step 4
2. Live ISO, on the console: `sudo passwd root`, `ip -br a`. Its sshd already
   accepts root; everything else runs remotely. Keep a laptop awake for the
   whole install: `ssh root@<ip> systemd-run --unit=keep-awake systemd-inhibit
   --what=sleep:idle:handle-lid-switch sleep infinity` (a transient unit
   survives the SSH session; NixOS `/etc` is read-only, so don't mask units or
   edit `sshd_config` there)
3. Hardware: `clan machines update-hardware-config <m> --target-host root@<ip>
   --backend nixos-facter` writes `facter.json` over plain SSH.
   `init-hardware-config` kexecs, which a live ISO does not need. Confirm the
   disk serial with `lsblk -o NAME,SIZE,MODEL,SERIAL` on the ISO and unplug or
   identify every other disk (installer USB included)
4. `clan vars generate <m>`
5. `CLAN_NO_COMMIT=1 clan machines install <m> --target-host
   'root@<ip>?ServerAliveInterval=15&ServerAliveCountMax=4' --phases disko,install
   --build-on local --update-hardware-config none`. `CLAN_NO_COMMIT` stops Clan's
   auto-commits so the change lands as a normal commit. nixos-anywhere forces
   `StrictHostKeyChecking=no` and `UserKnownHostsFile=/dev/null`, so known_hosts
   options passed to the install are ignored; the ISO's changing host key
   only matters to your own `ssh` calls. Don't run other SSH sessions against
   the ISO during the install: nixos-anywhere opens a fresh connection per
   command, and a burst can trip OpenSSH's per-source penalties
   (`kex_exchange_identification: ... Not allowed at this time`). The penalty
   expires; wait a few minutes and rerun the failed phase
6. Interrupted after disko: rerun with `--phases install` only if the ISO did
   not reboot (`findmnt /mnt` shows the target). After a reboot `/mnt` is gone
   and an install would land in the ISO's tmpfs: rerun from `disko`, or mount
   first with disko's `--mode mount`
7. First boot: `sudo tailscale up` on the console (the `tailscale` feature
   carries no auth key), then check `systemctl --failed`, `findmnt`, and that
   `ssh -p <identity sshPort> <m>` works. Later changes: `just deploy <m>`

### Not for agents
- `just switch`, `build`, `boot`, `home`, `deploy`: the owner deploys (build/switch go
  through `nh`; `deploy` takes `clan machines update` arguments, e.g. `--tags server`)
- `just update`: flake inputs are updated by Dependabot PRs
- `just clean`, `optimise`, `repair`, `bin/nix-install.sh`: host maintenance
- Do not commit or push unless asked. Never print values from `sops/` or `vars/`;
  generate secrets with `clan vars generate <machine>`, never by hand

### CI (`.github/workflows/`)
- `ci.yml`: `just check` (Linux; it evaluates darwin too), four target-based
  probe shards, and on PRs the `just report` summary against the base branch.
  Each shard compares its output against the matching subset of
  `tests/probe-errors.txt`; the required `probes` gate succeeds only when all
  four shards succeed. Pushes that only touch docs (`**/*.md`, `docs/`,
  `COPYING`) skip it; PRs always run it because the `dev` ruleset requires
  `check`, `probes` and `builds`, and a path-filtered required check never
  reports and blocks merge
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
- Waiting on a PR: one blocking `gh pr checks <N> --watch --interval 60`
  with a 30 min shell timeout, never sleep loops. Measured baseline (Oct 2026,
  PR #315): CI 531s from creation, probes job 525s, probe step 504s; latest
  `dev` push probes job 523s. After-change Actions timing is pending; no
  speedup is claimed before measurement. Right after `gh pr create`, checks
  take ~20 s to register. Still running past ~25 min: inspect
  `gh run view <id> --json jobs` instead of waiting longer

### Upstream references
When unsure how something works, read the source rather than guessing. Check
the version pinned in `flake.lock` first
- Clan: `git.clan.lol/clan/clan-core` (`clanServices/`, `nixosModules/clanCore/`,
  `pkgs/clan-cli/`, `docs/`)
- Options and module source: `NixOS/nixpkgs` (`nixos/modules/`), `nix-darwin/nix-darwin`,
  `nix-community/home-manager`
- Nix CLI behaviour: `NixOS/nix` (`src/nix/`, release notes under `doc/manual/`)
- Clan fleets to copy patterns from: `Mic92/dotfiles`, `nix-community/infra`
- Server defaults: `nix-community/srvos`
- Tools used here: `nix-community/nix-eval-jobs`, `nix-community/nh`,
  `numtide/treefmt-nix`, `cachix/git-hooks.nix`, `nix-community/nixos-facter-modules`,
  `nix-community/nix-index-database`

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
