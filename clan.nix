# Fleet inventory: machines, tags and service instances.
{ config, lib, ... }:
let
  liberion = import ./lib { inherit lib; };
  inherit (liberion) identity;
in
{
  meta.name = "liberion";
  # tailscale magicdns domain used for inter-machine clan communication
  meta.domain = "trex-gamut.ts.net";

  # every machine gets its class's base plus the profile of each of its tags
  # (modules/profiles/<tag>); keys come from machines/, since clan derives
  # inventory.machines from these
  machines =
    lib.mapAttrs
      (
        name: _:
        let
          machine = config.inventory.machines.${name};
        in
        liberion.machineModule machine.machineClass machine.tags (
          ./machines + "/${name}/home.nix"
        )
      )
      (lib.filterAttrs (_: kind: kind == "directory") (builtins.readDir ./machines));

  # tags are traits (modules/profiles/<tag>); clan adds all/nixos/darwin itself
  inventory.machines = {
    oulu = {
      description = "Lenovo V15 G4 IRU - Intel i7-1355U Build Server";
      tags = [
        "physical"
        "workstation"
        "headless"
        "server"
      ];
    };
    munich = {
      description = "ASUS PRIME B660-PLUS D4 - Intel i5-12400 & NVIDIA GTX 1080 Pascal";
      tags = [
        "desktop"
        "physical"
        "workstation"
        "nvidia"
      ];
    };
    solna = {
      description = "Laptop Workstation (SSD)";
      tags = [
        "archived"
        "physical"
        "laptop"
      ];
    };
    tampa = {
      description = "NixOS-WSL";
      tags = [
        "archived"
        "wsl"
      ];
    };
    zadar = {
      description = "Laptop Server (HDD / Headless)";
      tags = [
        "archived"
        "physical"
        "laptop"
      ];
    };
    beirut = {
      description = "Apple M4 MacBook (Primary Mac)";
      machineClass = "darwin";
      tags = [
        "desktop"
        "physical"
        "laptop"
        "workstation"
      ];
    };
    incheon = {
      description = "Apple M1 MacBook (Secondary Mac)";
      machineClass = "darwin";
      tags = [
        "archived"
        "physical"
        "laptop"
      ];
    };
  };

  inventory.instances = {
    # sshd + users are scoped by tag to machines installed through clan: users
    # sets mutableUsers = false and a generated password, sshd rotates host
    # keys. Only tag a machine `server` once `clan vars` exist for it
    # (oulu, munich, solna and zadar have them; beirut and incheon do not).
    sshd = {
      roles.server.tags = [ "server" ];
      roles.server.settings.authorizedKeys.annt-liberion = identity.keys.admin;
    };

    user-annt = {
      module.name = "users";
      roles.default.tags = [ "server" ];
      roles.default.settings = {
        inherit (identity) user;
        prompt = false;
      };
    };

    # every machine is reachable over tailscale magicdns as <user>@<name>:<sshPort>
    internet.roles.default = {
      settings = {
        inherit (identity) user;
        # openssh; 22 on the tailnet is tailscale ssh (no clan host keys)
        port = identity.sshPort;
      };
      machines = lib.mapAttrs (host: _: {
        settings = { inherit host; };
      }) config.inventory.machines;
    };
  };
}
