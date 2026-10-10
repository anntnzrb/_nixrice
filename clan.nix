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
      description = "Lenovo V15 G4 IRU - Intel Core i7-1355U - Build Server";
      tags = [
        "admin"
        "agents"
        "headless"
        "physical"
        "runner"
        "server"
        "server-laptop"
        "workstation"
      ];
    };
    munich = {
      description = "ASUS PRIME B660-PLUS D4 - Intel Core i5-12400 & NVIDIA GTX 1080 Pascal - Headless Server";
      tags = [
        "admin"
        "headless"
        "nvidia"
        "physical"
        "server"
        "workstation"
      ];
    };
    solna = {
      description = "HP 15-dw0083wm - Intel Pentium Silver N5000 - Headless Server";
      tags = [
        "admin"
        "agents"
        "headless"
        "laptop"
        "physical"
        "server"
        "server-laptop"
        "workstation"
      ];
    };
    tampa = {
      description = "ASUS PRIME B660-PLUS D4 - Intel Core i5-12400 - NixOS-WSL";
      tags = [
        "archived"
        "wsl"
      ];
    };
    zadar = {
      description = "ASUS GL502VMK - Intel Core i7-7700HQ - Headless Development Server";
      tags = [
        "admin"
        "agents"
        "headless"
        "laptop"
        "physical"
        "runner"
        "server"
        "server-laptop"
      ];
    };
    beirut = {
      description = "Apple MacBook Air 13-inch - Apple M4 - Primary Mac";
      machineClass = "darwin";
      tags = [
        "admin"
        "desktop"
        "laptop"
        "physical"
        "workstation"
      ];
    };
    incheon = {
      description = "Apple MacBook - Apple M1 - Secondary Mac";
      machineClass = "darwin";
      tags = [
        "archived"
        "laptop"
        "physical"
      ];
    };
  };

  modules.remote-builders = ./modules/services/remote-builders;
  modules.cachix-deploy = ./modules/services/cachix-deploy;

  inventory.instances = {
    wifi = {
      roles.default = {
        tags = [ "server-laptop" ];
        settings.networks.home = { };
      };
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
