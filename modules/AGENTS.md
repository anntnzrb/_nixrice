# AGENTS.md - Module System

One module = one feature, at `<platform>/<category>/<feature>/default.nix`, declaring
`liberion.<category>.<feature>.enable` (option path mirrors the directory path).

```
modules/
├── darwin/  nixos/   # system modules (nix-darwin / NixOS)
├── shared/           # system modules valid on both; imported by both entrypoints
├── home/             # Home Manager modules
├── toggle.nix        # factory for enable-only modules (not auto-imported)
└── default.nix, darwin.nix, home.nix   # entrypoints
```

### Discovery
- Every `default.nix` below an entrypoint's tree is imported automatically
  (`lib.liberion.fs.getDefaultFiles`); adding a feature needs no import list edit.
- Sibling `*.nix` files are only imported when the module asks with
  `getModuleFiles { path = ./.; ignore = [ "data.nix" ]; }` - list plain data files
  in `ignore`, or they get imported as modules.

### Writing a module
Enable-only feature (most modules):

```nix
import ../../../toggle.nix "cli.btop" (
  { config, ... }:
  {
    programs.btop.enable = true;
  }
)
```

Install one package: `import ../../../toggle.nix "cli.husky" "husky"`.

Feature with more options: declare them explicitly and gate on `cfg.enable`:

```nix
{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  cfg = config.liberion.cli.ssh;
in
{
  options.liberion.cli.ssh = {
    enable = mkOptDisabled';
    identityFile = mkOpt' lib.types.str "~/.ssh/id_ed25519";
  };

  config = lib.mkIf cfg.enable { programs.ssh.enable = true; };
}
```

Helpers (`lib/default.nix`): `mkOpt' type default` (description-free option),
`mkOptDisabled'` / `mkOptEnabled'` (bool, false / true), `on` / `off`
(`{ enable = true/false; }`, e.g. `liberion.cli.git = on;`).

Baselines (`nixos/default.nix`, `darwin/default.nix`, `home/default.nix`,
`home/xdg`, `shared/{nix,environment}`) apply to every host; keep new features opt-in.

### Gotchas
- `liberion.suites.desktop` exists in both the system and the Home Manager option
  trees; they are different options. Use `just enabled <machine>` to see what is on.
- Reordering list definitions changes drvPaths even when behaviour does not:
  `home.packages`, `environment.systemPackages` and Homebrew casks merge in module
  order. Check with `just drvdiff` and explain any diff.
- Some unused modules do not evaluate when enabled (their probe reads
  `eval-error`, e.g. sway/sxhkd need `home.sessionVariables.TERMINAL`). A refactor
  must keep the probe unchanged unless it fixes the module on purpose.
