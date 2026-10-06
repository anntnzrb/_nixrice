{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  port = "6767";
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
        "${config.home.homeDirectory}/.local/bin/paseo"
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
    (lib.liberion.userJob {
      name = "paseo-update";
      description = "Restart the Paseo daemon onto its newest release when idle";
      schedule = "nightly";
      timeout = 900;
      command = lib.liberion.agentsSync config ++ [
        "job"
        "paseo-update"
        "--service"
        (
          if pkgs.stdenv.hostPlatform.isLinux then
            "paseo.service"
          else
            "org.nix-community.home.paseo"
        )
      ];
    })
  ];
}
