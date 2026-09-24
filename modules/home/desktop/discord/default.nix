{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.desktop.discord;
in
{
  options.${namespace}.desktop.discord = {
    enable = mkOptDisabled';
  };
  config = lib.mkIf cfg.enable { home.packages = [ pkgs.discord ]; };
}
