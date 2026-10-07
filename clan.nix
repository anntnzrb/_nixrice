{ config, lib, ... }:
let
  liberion = import ./lib {
    inherit lib;
    root = ./.;
  };
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
        "admin"
        "physical"
        "workstation"
        "headless"
        "server"
      ];
    };
    munich = {
      description = "ASUS PRIME B660-PLUS D4 - Intel i5-12400 & NVIDIA GTX 1080 Pascal";
      tags = [
        "admin"
        "physical"
        "workstation"
        "server"
        "headless"
        "nvidia"
      ];
    };
    solna = {
      description = "HP 15-dw0083wm - Pentium N5000 Headless Server";
      tags = [
        "admin"
        "physical"
        "laptop"
        "workstation"
        "server"
        "headless"
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
        "admin"
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
  modules.cachix-deploy = ./modules/services/cachix-deploy;

  inventory.instances = {
    wifi = {
      roles.default.machines.solna.settings.networks.home = { };
    };

    remote-builders = {
      module = {
        input = "self";
        name = "remote-builders";
      };
      roles.builder.machines.oulu.settings.maxJobs = 6;
      roles.client.machines.beirut.settings.defaultBuilders = [ "oulu" ];
    };

    cachix-deploy = {
      module = {
        input = "self";
        name = "cachix-deploy";
      };
      roles.agent.machines = {
        beirut = { };
        oulu = { };
        solna = { };
      };
    };

    # Host keys and certificates only; root has no SSH keys, the admin user
    # logs in and escalates with sudo.
    sshd.roles.server = {
      tags = [ "server" ];
      settings.certificate.searchDomains = [ liberion.mdnsDomain ];
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

    lan = {
      module.name = "internet";
      roles.default = {
        settings = {
          inherit (identity) user;
          port = identity.sshPort;
        };
        machines = lib.mapAttrs (name: _: {
          settings.host = "${name}.${liberion.mdnsDomain}";
        }) config.inventory.machines;
      };
    };
  };
}
