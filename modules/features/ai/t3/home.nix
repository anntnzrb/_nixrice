{
  config,
  inputs,
  lib,
  ...
}:
let
  t3 = lib.liberion.agentsSync config ++ [ "t3" ];
in
{
  imports = [
    inputs.self.homeModules.ai-agents
    # T3 writes and owns its own t3code service; these jobs install it on a
    # fresh host, keep it on the floating channel, and refresh Claude models.
    (lib.liberion.userJob {
      name = "t3-update";
      description = "Install or update T3 Code when no thread runs";
      schedule = "nightly";
      timeout = 900;
      command = t3 ++ [ "auto-update" ];
    })
    (lib.liberion.userJob {
      name = "t3-refresh-models";
      description = "Refresh T3 Code's Claude models from the gateway catalog";
      schedule = 900;
      startup = 300;
      command = t3 ++ [ "refresh-models" ];
    })
  ];
}
