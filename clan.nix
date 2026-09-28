{ config, lib, ... }:
let
  liberion = import ./lib { inherit lib; };
  inherit (liberion) identity;
in
{
  meta.name = "liberion";
  meta.domain = "trex-gamut.ts.net";

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
        "physical"
        "workstation"
        "server"
        "headless"
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

  modules.remote-builders = ./modules/services/remote-builders;

  inventory.instances = {
    remote-builders = {
      module = {
        input = "self";
        name = "remote-builders";
      };
      roles.builder.machines.oulu.settings.maxJobs = 6;
      roles.client.machines.beirut.settings.defaultBuilders = [ "oulu" ];
    };

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

    internet.roles.default = {
      settings = {
        inherit (identity) user;
        port = identity.sshPort;
      };
      machines = lib.mapAttrs (host: _: {
        settings = { inherit host; };
      }) config.inventory.machines;
    };
  };
}
