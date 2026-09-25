# AGENTS.md - Modules

```
modules/
├── base/<name>/       # always imported (every machine of the class / every home)
├── features/<category>/<name>/   # imported by machines, profiles or other features
└── profiles/<tag>/    # imported into machines tagged <tag> in clan.nix
```

Each directory holds class files: `nixos.nix`, `darwin.nix`, `home.nix`, and
`system.nix` (NixOS and nix-darwin alike). `lib/default.nix` discovers them and
exports every feature by directory name as `self.nixosModules.<name>`,
`self.darwinModules.<name>` and `self.homeModules.<name>`. Other files in a
directory are helpers, imported explicitly; paths containing `/_` are ignored.
Directory names are unique across features and profiles.

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
- Import order is merge order: moving an import reorders `home.packages` /
  `environment.systemPackages` and changes drvPaths without changing behaviour.
  `just drvdiff`, then explain the diff with `nix-diff`.
- A probe reading `eval-error` is expected where the module cannot apply to the
  probe host: Linux-only home features on beirut, exclusive features (grub vs
  systemd-boot, dhcp vs networkmanager, headless vs desktop). A refactor must keep
  every probe unchanged unless it changes the module on purpose.
- oulu opts out of two base modules with `disabledModules`.
