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

  # A synthetic NixOS host: the nixos base, the owner's Home Manager user with
  # the home base, and just enough to build a toplevel. It is evaluated through
  # a clan of its own (the fleet's specialArgs and nixpkgs) whose directory has
  # no machines/, so no real machine, tag or profile leaks into a probe.
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
      # a boot loader feature (grub, systemd-boot, wsl) may take over
      boot.loader.grub.enable = lib.mkDefault false;
      # a filesystem feature (disko-xfs, btrfs-labels) may take over
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
