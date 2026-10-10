{ config, lib, ... }:
let
  cfg = config.liberion.network.sshd;
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
    settings = import ./hardening.nix;
  };
}
