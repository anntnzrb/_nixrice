# Every machine and standalone home as a build target:
# [ { name; attr; system; out; } ], `attr` relative to the flake root.
{ flake }:
let
  f = builtins.getFlake flake;
  inherit (f.inputs.nixpkgs) lib;
  target = name: attr: drv: {
    inherit name attr;
    inherit (drv) system;
    out = drv.outPath;
  };
in
lib.mapAttrsToList (
  n: c:
  target n "nixosConfigurations.${n}.config.system.build.toplevel"
    c.config.system.build.toplevel
) f.nixosConfigurations
++ lib.mapAttrsToList (
  n: c: target n "darwinConfigurations.${n}.system" c.system
) f.darwinConfigurations
++ lib.mapAttrsToList (
  n: h:
  target n "homeConfigurations.\"${n}\".activationPackage" h.activationPackage
) f.homeConfigurations
