# Fleet inventory: machines, tags and service instances.
{ config, lib, ... }:
let
  identity = import ./identity.nix;
in
{
  meta.name = "liberion";
  # tailscale magicdns domain used for inter-machine clan communication
  meta.domain = "trex-gamut.ts.net";

  # every machine gets the liberion module set of its class
  # (keys from machines/, since clan derives inventory.machines from these)
  machines =
    lib.mapAttrs
      (name: _: {
        imports = [
          config.self."${config.inventory.machines.${name}.machineClass}Modules".default
        ];
      })
      (lib.filterAttrs (_: kind: kind == "directory") (builtins.readDir ./machines));

  inventory.machines = {
    oulu = {
      description = "Lenovo V15 G4 IRU - Intel i7-1355U Build Server";
      tags = [
        "physical"
        "workstation"
        "headless"
        "nixos"
      ];
    };
    munich = {
      description = "ASUS PRIME B660-PLUS D4 - Intel i5-12400 & NVIDIA GTX 1080 Pascal";
      tags = [
        "physical"
        "workstation"
        "nvidia"
        "nixos"
      ];
    };
    solna = {
      description = "Laptop Workstation (SSD)";
      tags = [
        "physical"
        "laptop"
        "workstation"
        "nixos"
      ];
    };
    tampa = {
      description = "NixOS-WSL";
      tags = [
        "wsl"
        "nixos"
      ];
    };
    zadar = {
      description = "Laptop Server (HDD / Headless)";
      tags = [
        "physical"
        "laptop"
        "headless"
        "nixos"
      ];
    };
    beirut = {
      description = "Apple M4 MacBook (Primary Mac)";
      machineClass = "darwin";
      tags = [
        "physical"
        "darwin"
        "laptop"
        "workstation"
      ];
    };
    incheon = {
      description = "Apple M1 MacBook (Secondary Mac)";
      machineClass = "darwin";
      tags = [
        "physical"
        "darwin"
        "laptop"
      ];
    };
  };

  inventory.instances = {
    # sshd + users are scoped to machines installed through clan: users sets
    # mutableUsers = false and a generated password, sshd rotates host keys.
    # extend a machine only after `clan vars` exist for it (munich/solna/zadar
    # already have them).
    sshd = {
      roles.server.machines.oulu = { };
      roles.server.settings.authorizedKeys.annt-liberion = identity.keys.admin;
    };

    user-annt = {
      module.name = "users";
      roles.default.machines.oulu = { };
      roles.default.settings = {
        inherit (identity) user;
        prompt = false;
      };
    };

    # every machine is reachable over tailscale magicdns as annt@<name>:2222
    internet.roles.default = {
      settings = {
        inherit (identity) user;
        # openssh; 22 on the tailnet is tailscale ssh (no clan host keys)
        port = 2222;
      };
      machines = lib.mapAttrs (host: _: {
        settings = { inherit host; };
      }) config.inventory.machines;
    };
  };
}
