{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.cli.omnix;
in
{
  options.liberion.cli.omnix = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.om = "${lib.getExe pkgs.nix} --accept-flake-config run github:juspay/omnix --";
  };
}
