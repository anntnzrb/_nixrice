{ lib, config, ... }:
let
  cfg = config.liberion.network.ssh;
in
{
  config = lib.mkIf cfg.enable {
    services.openssh = {
      inherit (cfg) enable;
      ports = [ cfg.port ];
      settings.PasswordAuthentication = false;
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
