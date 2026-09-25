{ config, ... }:
let
  cfg = config.liberion.network.ssh;
in
{
  config = {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
      settings.PasswordAuthentication = false;
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
