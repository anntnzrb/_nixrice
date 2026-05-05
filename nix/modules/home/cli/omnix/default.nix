{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.omnix;
in
{
  options.${namespace}.cli.omnix = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.om = "${lib.getExe pkgs.nix} --accept-flake-config run github:juspay/omnix --";
  };
}
