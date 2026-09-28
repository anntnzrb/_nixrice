{ lib, config, ... }:
let
  cfg = config.liberion.network.ssh;
in
{
  config = {
    services.openssh.enable = true;

    launchd.daemons = lib.mkIf (cfg.port != 22) {
      "sshd-${toString cfg.port}" = {
        serviceConfig = {
          ProgramArguments = [
            "/usr/sbin/sshd"
            "-D"
            "-p"
            (toString cfg.port)
          ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    };
  };
}
