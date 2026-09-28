{
  flake,
  target ? null,
  name ? null,
}:
let
  f = builtins.getFlake flake;
  inherit (f.inputs.nixpkgs) lib;
  inherit (import "${f}/identity.nix") user;

  probeClan = f.inputs.clan-core.lib.clan {
    self = f;
    directory = f + "/scripts/ci";
    inherit (f.clan) specialArgs pkgsForSystem;
    meta = { inherit (f.clan.inventory.meta) name domain; };
    machines.probe = {
      imports = [
        f.nixosModules.default
        { home-manager.users.${user}.imports = [ f.homeModules.default ]; }
      ];
      nixpkgs.hostPlatform = "x86_64-linux";
      users.users.${user}.isNormalUser = true;
      boot.loader.grub.enable = lib.mkDefault false;
      fileSystems."/" = lib.mapAttrs (_: lib.mkDefault) {
        device = "/dev/disk/by-label/probe";
        fsType = "ext4";
      };
    };
  };
  probe = probeClan.config.nixosConfigurations.probe;

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
    nixos-probe = system probe f.nixosModules;
    darwin-beirut = system f.darwinConfigurations.beirut f.darwinModules;
    home-probe = home probe;
    home-beirut = home f.darwinConfigurations.beirut;
  };
  names = t: lib.attrNames (removeAttrs t.modules [ "default" ]);
  evalTarget =
    t: name:
    (t.sys.extendModules { modules = [ (t.wrap t.modules.${name}) ]; })
    .config.system.build.toplevel;
in
if target != null && name != null then
  evalTarget targets.${target} name
else
  lib.mapAttrs (_: t: lib.genAttrs (names t) (name: evalTarget t name)) targets
