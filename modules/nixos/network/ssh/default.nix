{ lib, config, ... }:
let
  cfg = config.liberion.network.ssh;
in
{
  imports = [
    (lib.liberion.fs.getFile "modules/shared/network/ssh/default.nix")
  ];

  config = lib.mkIf cfg.enable {
    services.openssh = {
      inherit (cfg) enable;
      ports = [ cfg.port ];
      settings.PasswordAuthentication = false;
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
