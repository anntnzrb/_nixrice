## AGENTS.md

This repo is a Nix Flake–driven dotfiles system built atop `snowfall-lib`. Everything custom lives under the `liberion` namespace. Think in layers: reusable modules (`nix/modules`) → machine/system definitions (`nix/systems/*/<host>`) → user/home compositions (`nix/homes/*/<user@host>`). The `bin/rice.sh` script is the single operational interface.

### 1. Mental Model
1. `flake.nix` wires inputs and delegates to `snowfall-lib.mkFlake` with `src = ./nix`.
2. `nix/lib/module/default.nix` defines option helpers (`mkOptDisabled'`, `on.enable = true`, `off.enable = false`) used everywhere.
3. Modules are small, orthogonal, opt‑in; enabling = setting `liberion.*.* = on` inside a home/system file.
4. Cross‑module effects are explicit: a module may both set NixOS/Darwin/Home Manager options and flip other `liberion.*` feature flags.
5. Host configs assemble feature toggles; no logic duplication there—logic belongs in modules.

### 2. Creating / Extending a Module (Pattern)
File location rule: pick the closest scope & platform: e.g. add a CLI tool → `nix/modules/home/cli/<tool>/default.nix`.
Skeleton:
```nix
{ config, lib, namespace, ... }:
let inherit (lib.${namespace}.module) mkOptDisabled';
    cfg = config.${namespace}.cli.someTool;
in {
  options.${namespace}.cli.someTool.enable = mkOptDisabled';
  config = lib.mkIf cfg.enable {
    programs.someTool.enable = true;
    # extra integration (e.g. keybindings, theming) here
  };
}
```
Enable it in a home file:
```nix
liberion.cli.someTool = on; # becomes cfg.enable = true
```

### 3. Example: Feature + Integration
`nix/modules/home/cli/btop/default.nix`:
* Defines `options.liberion.cli.btop.enable = mkOptDisabled'`
* On enable: configures `programs.btop.settings` AND injects an sxhkd keybinding using `${config.home.sessionVariables.TERMINAL}` → demonstrates cross‑feature awareness.

### 4. Host Composition Pattern
See `nix/homes/x86_64-linux/annt@munich/default.nix`:
* Imports helpers: `inherit (lib.${namespace}.module) on off`
* Declares session variables once (`TERMINAL`, `BROWSER`, etc.) consumed by modules.
* Enables window manager variants via nested attrsets; unused options remain off (never delete, just toggle).
* Uses simple lists (`autoStart.defaults ++ autoStart.xrandr`) instead of embedding logic.

### 5. Overlays & Inputs
`flake.nix` pins multiple channels (`nixpkgs`, `nixpkgs-stable`, `nixpkgs-unstable`) and propagates them via `follows`. Prefer existing inputs—only add new ones if a package/module genuinely needs an unprovided source.

### 6. Workflows (Always use script wrappers)
Build (no activation):
```bash
./bin/rice.sh build
```
Switch system (NixOS/Darwin):
```bash
./bin/rice.sh switch
```
Home Manager only (user@host):
```bash
./bin/rice.sh hm-switch annt munich
```
Format / lint:
```bash
./bin/rice.sh fmt
```
Update inputs:
```bash
./bin/rice.sh nix-flake-update-all
```
Target one input (commits lock automatically):
```bash
./bin/rice.sh nix-flake-update nixpkgs-unstable
```

### 7. When Editing
* Never duplicate a setting: put logic in module; home/system files only toggle & supply data (like lists, theme picks, host specifics).
* Use `lib.mkIf cfg.enable` gating—avoid ad‑hoc `if` expressions.
* Use existing session variables; add new ones in the host file only if multiple modules need them.

### 8. Adding Cross‑Feature Hooks
If a feature needs another (e.g. keybindings for a tool): within the first module set the second module's subtree instead of editing the consumer. Example in btop module setting `services.sxhkd.keybindings`.

### 9. Style / Naming
* Attribute path mirrors directory path.
* Lowercase with dashes for directories; camelCase acceptable only for option leafs if tool upstream uses it.
* Keep modules minimal: one responsibility, one enable switch.

### 10. Safe Changes Checklist
1. Add module file.
2. Expose `enable` option via helper.
3. Gate config with `lib.mkIf`.
4. Enable in target home/system.
5. Run build → switch.

Questions or ambiguities: prefer following existing patterns from closest analogous module.

