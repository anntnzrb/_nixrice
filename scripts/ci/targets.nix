# Every machine, standalone home and dev shell as a build target (the shell
# so a fresh sandbox, e.g. an Amp orb, substitutes clan-cli instead of building it):
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
++ lib.mapAttrsToList (
  s: shells: target "devshell-${s}" "devShells.${s}.default" shells.default
) f.devShells
