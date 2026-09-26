# Every live machine, standalone home and dev shell as a build target (the shell
# so a fresh sandbox, e.g. an Amp orb, substitutes clan-cli instead of building it);
# machines tagged `archived` and retired homes (annt@wsl, from archived tampa)
# are neither built nor pushed to Cachix:
# [ { name; attr; system; out; } ], `attr` relative to the flake root.
{ flake }:
let
  f = builtins.getFlake flake;
  inherit (f.inputs.nixpkgs) lib;
  inherit (import "${f}/identity.nix") user;
  target = name: attr: drv: {
    inherit name attr;
    inherit (drv) system;
    out = drv.outPath;
  };
  live = lib.filterAttrs (n: _: !(builtins.elem "archived" f.clan.inventory.machines.${n}.tags));
  retiredHomes = [ "${user}@wsl" ];
in
lib.mapAttrsToList (
  n: c:
  target n "nixosConfigurations.${n}.config.system.build.toplevel"
    c.config.system.build.toplevel
) (live f.nixosConfigurations)
++ lib.mapAttrsToList (
  n: c: target n "darwinConfigurations.${n}.system" c.system
) (live f.darwinConfigurations)
++ lib.mapAttrsToList (
  n: h:
  target n "homeConfigurations.\"${n}\".activationPackage" h.activationPackage
) (removeAttrs f.homeConfigurations retiredHomes)
++ lib.mapAttrsToList (
  s: shells: target "devshell-${s}" "devShells.${s}.default" shells.default
) f.devShells
