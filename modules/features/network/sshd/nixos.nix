{ lib, config, ... }:
let
  cfg = config.liberion.network.ssh;
in
{
  config.services.openssh = {
    enable = true;
    ports = lib.unique [
      22
      cfg.port
    ];
    openFirewall = true;
    authorizedKeysInHomedir = false;
    settings = {
      # Deploys and admin log in as the user and escalate with sudo.
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
