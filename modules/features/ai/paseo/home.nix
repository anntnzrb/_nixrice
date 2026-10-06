{
  config,
  inputs,
  lib,
  ...
}:
let
  port = "6767";
  wrapper = "${config.home.homeDirectory}/.local/bin/paseo";
in
{
  imports = [
    inputs.self.homeModules.ai-agents
    # Loopback only; on NixOS the system module publishes it to the tailnet.
    # Launch overrides take precedence over ~/.paseo/config.json.
    (lib.liberion.userService {
      name = "paseo";
      description = "Paseo agent daemon";
      command = [
        wrapper
        "daemon"
        "run"
      ];
      environment = {
        PASEO_LISTEN = "127.0.0.1:${port}";
        PASEO_RELAY_ENABLED = "false";
        PASEO_WEB_UI_ENABLED = "true";
        PASEO_HOSTNAMES = ".ts.net";
        PASEO_TRUSTED_PROXIES = "loopback";
      };
    })
    (lib.liberion.idleRestartJob {
      service = "paseo";
      kind = "paseo";
      inherit wrapper;
    })
  ];
}
