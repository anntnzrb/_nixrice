# Lists every feature/profile per probe host ("<target> <name>") or, given
# `target` and `name`, evaluates that host with the module imported, so
# modules no machine uses are checked like live ones.
{
  flake,
  target ? null,
  name ? null,
}:
let
  f = builtins.getFlake flake;
  inherit (f.inputs.nixpkgs) lib;
  inherit (import "${f}/identity.nix") user;

  home = sys: {
    inherit sys;
    modules = f.homeModules;
    wrap = m: { home-manager.users.${user}.imports = [ m ]; };
  };
  system = sys: modules: {
    inherit sys modules;
    wrap = m: m;
  };

  targets = {
    # solna runs a desktop, so X/desktop modules probe without headless conflicts
    nixos-solna = system f.nixosConfigurations.solna f.nixosModules;
    darwin-beirut = system f.darwinConfigurations.beirut f.darwinModules;
    home-zadar = home f.nixosConfigurations.zadar;
    home-beirut = home f.darwinConfigurations.beirut;
  };
  names = t: lib.attrNames (removeAttrs t.modules [ "default" ]);
in
if target == null then
  lib.concatStrings (
    lib.concatLists (
      lib.mapAttrsToList (n: t: map (m: "${n} ${m}\n") (names t)) targets
    )
  )
else
  let
    t = targets.${target};
  in
  (t.sys.extendModules { modules = [ (t.wrap t.modules.${name}) ]; })
  .config.system.build.toplevel.drvPath
