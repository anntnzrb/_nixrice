# AGENTS.md - Modules

```
modules/
├── base/<name>/       # always imported (every machine of the class / every home)
├── features/<category>/<name>/   # imported by machines, profiles or other features
├── profiles/<tag>/    # imported into machines tagged <tag> in clan.nix
└── services/<name>/   # in-repo Clan services (_class = "clan.service")
```

Each directory holds class files: `nixos.nix`, `darwin.nix`, `home.nix`, and
`system.nix` (NixOS and nix-darwin alike). `lib/default.nix` discovers them and
exports every feature by directory name as `self.nixosModules.<name>`,
`self.darwinModules.<name>` and `self.homeModules.<name>`. Other files in a
directory are helpers, imported explicitly; paths containing `/_` are ignored.
Directory names are unique across features and profiles.

### Profiles are traits
Each tag `<t>` imports `modules/profiles/<t>/` into machines carrying it.
Profiles never import other profiles. Clan adds computed tags (`all`,
`nixos`, `darwin`) automatically (never list them by hand). Other tags
without a matching directory in `modules/profiles/` are descriptive.

### Clan services
In-repo Clan services live in `modules/services/<name>/default.nix`
(`_class = "clan.service"`). Register them in `clan.nix` under
`modules.<name> = ./modules/services/<name>;` and instantiate them under
`inventory.instances.<name>` with `module = { input = "self"; name = "<name>"; };`.
For example, `remote-builders` defines a `builder` role (NixOS; sets `maxJobs`
and trusts the owner for remote builds) and a `client` role (nix-darwin;
generates `/etc/nix/builders/<name>` per builder, pins builder OpenSSH host
keys, sets `ConnectTimeout 5`, and configures `defaultBuilders`).

### Adding a feature
Drop a directory in `modules/features/<category>/<name>/` with the class file(s).
**Importing it is enabling it** - there are no `enable` toggles:

```nix
# modules/features/cli/btop/home.nix
{
  programs.btop = {
    enable = true;
    settings.vim_keys = true;
  };
}
```

Then import it where it is wanted:
`imports = with inputs.self.homeModules; [ btop ];` in a machine's `home.nix`,
`modules/base/common/home.nix` (every home) or another feature.

A feature with both a system file and `home.nix` also hands the home part to the
owner's Home Manager configuration when a machine imports it.

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

### Gotchas
- Import order is merge order for list options. For package lists that only
  changes drvPaths, but PATH (`home.sessionPath`) and script snippets are
  order-sensitive: pin those with `lib.mkBefore`/`lib.mkAfter` instead of relying
  on import order. `just report` shows PATH and script changes.
- `tests/probe-errors.txt` lists the modules expected not to evaluate on their
  probe host (the synthetic base-only NixOS probe host for Linux features and
  homes, and the primary Mac for darwin features and homes): genuine platform
  mismatches, such as Linux-only home features probed on the Mac host, or
  darwin-only home features probed on the synthetic Linux probe host.
  `just probes` fails when that set changes; update the list only for such
  genuine cases.
