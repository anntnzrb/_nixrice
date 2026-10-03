{ flake }:
let
  f = builtins.getFlake flake;
  inherit (f.inputs.nixpkgs) lib;
  inherit
    (import "${f}/lib" {
      inherit lib;
      root = "${f}";
    })
    isArchived
    ;
  inherit (import "${f}/identity.nix") user;
  target = name: attr: drv: {
    inherit name attr;
    inherit (drv) system;
    out = drv.outPath;
  };
  live = lib.filterAttrs (n: _: !(isArchived f.clan.inventory.machines.${n}));
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
