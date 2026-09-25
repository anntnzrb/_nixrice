# Lists toggles no host enables ("<target> <path>") or, given `target` and
# `path`, evaluates that host with the toggle (and all toggles below it) on.
{
  flake,
  target ? null,
  path ? null,
}:
let
  f = builtins.getFlake flake;
  inherit (f.inputs.nixpkgs) lib;
  targets = {
    nixos-zadar = {
      sys = f.nixosConfigurations.zadar;
      get = c: c.liberion;
      set = m: m;
    };
    home-zadar = {
      sys = f.nixosConfigurations.zadar;
      get = c: c.home-manager.users.annt.liberion;
      set = m: { home-manager.users.annt = m; };
    };
    darwin-beirut = {
      sys = f.darwinConfigurations.beirut;
      get = c: c.liberion;
      set = m: m;
    };
    home-beirut = {
      sys = f.darwinConfigurations.beirut;
      get = c: c.home-manager.users.annt.liberion;
      set = m: { home-manager.users.annt = m; };
    };
  };
  disabled =
    prefix: v:
    if builtins.isAttrs v && !(lib.isDerivation v) then
      lib.concatLists (
        lib.mapAttrsToList (
          n: x:
          let
            r = builtins.tryEval x;
          in
          if !r.success || n == "enable" then
            lib.optional (n == "enable" && r.success && r.value == false) (
              lib.concatStringsSep "." prefix
            )
          else
            disabled (prefix ++ [ n ]) r.value
        ) v
      )
    else
      [ ];
  paths = t: disabled [ ] (t.get t.sys.config);
  below = p: q: lib.hasPrefix "${p}." q;
  top =
    t:
    let
      ps = paths t;
    in
    builtins.filter (p: !(builtins.any (q: below q p) ps)) ps;
in
if target == null then
  lib.concatStrings (
    lib.concatLists (
      lib.mapAttrsToList (n: t: map (p: "${n} ${p}\n") (top t)) targets
    )
  )
else
  let
    t = targets.${target};
    on = map (q: lib.setAttrByPath (lib.splitString "." q ++ [ "enable" ]) true) (
      [ path ] ++ builtins.filter (below path) (paths t)
    );
  in
  (t.sys.extendModules { modules = map (m: t.set { liberion = m; }) on; })
  .config.system.build.toplevel.drvPath
