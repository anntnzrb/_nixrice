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
    "nightly"
    "--settings"
    "${settings}/settings.json"
    "--gateway"
    gateway
  ];
in
{
  options.liberion.ai.t3.settings = lib.liberion.module.mkOpt' json.type { };

  config.liberion.ai.t3.settings = import ./settings.nix;

  imports = [
    inputs.self.homeModules.ai-agents
    # T3 writes and supervises its own t3code service; these jobs install it on
    # a fresh host, keep it on the release channel, and keep its settings and
    # Claude models current.
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
  ];
}
