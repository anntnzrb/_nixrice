{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  gateway = import (
    inputs.self + "/modules/features/ai/cliproxyapi/endpoint.nix"
  ) osConfig.clan.core.settings.domain;
  settings = (pkgs.formats.json { }).generate "t3-settings.json" (
    import ./settings.nix
  );
  t3ctl = [
    (lib.getExe pkgs.python3)
    "${./t3ctl.py}"
  ];
  flags = [
    "--channel"
    "nightly"
    "--settings"
    "${settings}"
    "--gateway"
    gateway
  ];
in
{
  imports = [
    inputs.self.homeModules.ai-agents
    # T3 writes and supervises its own t3code service; these jobs install it on
    # a fresh host, keep it on the release channel, and keep its settings and
    # Claude models current.
    (lib.liberion.userJob {
      name = "t3-update";
      description = "Install or update T3 Code when no thread runs";
      schedule = "nightly";
      timeout = 900;
      command = t3ctl ++ [ "update" ] ++ flags;
    })
    (lib.liberion.userJob {
      name = "t3-refresh-models";
      description = "Refresh T3 Code's Claude models from the gateway catalog";
      schedule = 900;
      startup = 300;
      command = t3ctl ++ [ "refresh-models" ] ++ flags;
    })
  ];
}
