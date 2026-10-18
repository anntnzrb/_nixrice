{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  json = pkgs.formats.json { };
  gateway = import (
    inputs.self + "/modules/features/ai/cliproxyapi/endpoint.nix"
  ) osConfig.clan.core.settings.domain;
  settings = pkgs.linkFarm "t3-settings" [
    {
      name = "settings.json";
      path = json.generate "t3-settings.json" config.liberion.ai.t3.settings;
    }
    {
      name = "client-settings.json";
      path = ./client-settings.json;
    }
  ];
  t3ctl = [
    (lib.getExe (
      lib.liberion.pythonScript pkgs {
        name = "t3ctl";
        script = ./cli.py;
      }
    ))
  ];
  flags = [
    "--channel"
    "stable"
    "--settings"
    "${settings}/settings.json"
    "--gateway"
    gateway
  ];
  stable = "${config.home.homeDirectory}/.t3/runtime/stable/t3";
  telemetry.T3CODE_TELEMETRY_ENABLED = "false";
in
{
  imports = [
    inputs.self.homeModules.ai-agents
    (lib.liberion.userJob {
      name = "t3-update";
      description = "Install or update T3 Code when no thread runs";
      schedule = 3600;
      startup = 300;
      timeout = 900;
      command = t3ctl ++ [ "update" ] ++ flags;
    })
    (lib.liberion.userJob {
      name = "t3-sync";
      description = "Apply T3 Code settings and Claude models from the gateway catalog";
      schedule = 900;
      startup = 300;
      command = t3ctl ++ [ "sync" ] ++ flags;
    })
    (
      { pkgs, ... }@args:
      let
        service = lib.liberion.userService {
          name = "t3-service";
          description = "T3 Code service launcher";
          command = [
            stable
            "__service-launcher"
          ];
          environment = telemetry // {
            T3CODE_HOME = "${config.home.homeDirectory}/.t3";
          };
        } args;
      in
      {
        inherit (service) imports;
        config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
          removeAttrs service [ "imports" ]
        );
      }
    )
  ];

  options.liberion.ai.t3.settings = lib.liberion.module.mkOpt' json.type { };

  config = {
    liberion.ai.t3.settings = import ./settings.nix;
    home.sessionVariables = telemetry;
    xdg.configFile."systemd/user/t3code.service.d/telemetry.conf" =
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        {
          text = lib.generators.toINI { listsAsDuplicateKeys = true; } {
            Service.Environment = lib.mapAttrsToList (
              name: value: "${name}=${value}"
            ) telemetry;
          };
        };
    liberion.maintenance.tasks.t3.command = t3ctl ++ [ "prune" ] ++ flags;
    launchd.agents = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      t3-service.config = {
        ExitTimeOut = 90;
        ProcessType = "Interactive";
        RunAtLoad = lib.mkForce false;
        KeepAlive = lib.mkForce {
          PathState."${config.home.homeDirectory}/.t3/runtime/stable.enabled" = true;
        };
      };
    };
  };
}
