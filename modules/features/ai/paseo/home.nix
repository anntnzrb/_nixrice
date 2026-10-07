{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  port = "6767";
  wrapper = "${config.home.homeDirectory}/.local/bin/paseo";
  cfg = config.liberion.ai.paseo;
in
{
  options.liberion.ai.paseo.autostart = lib.liberion.module.mkOptEnabled';

  config = lib.mkIf (!cfg.autostart) {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "liberion.ai.paseo.autostart = false is only implemented for systemd";
      }
    ];
    systemd.user.services = {
      paseo.Install.WantedBy = lib.mkForce [ ];
      # `systemctl restart` would start a stopped daemon.
      paseo-update.Service.ExecCondition = "${pkgs.systemd}/bin/systemctl --user is-active --quiet paseo.service";
    };
  };

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
