{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.husky;
in
{
  options.${namespace}.cli.husky = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable { home.packages = with pkgs; [ husky ]; };
}
