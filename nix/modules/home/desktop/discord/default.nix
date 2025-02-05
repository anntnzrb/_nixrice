{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.desktop.discord;
in
{
  options.${namespace}.desktop.discord = {
    enable = mkOptBool';
  };
  config = lib.mkIf cfg.enable { home.packages = [ pkgs.discord ]; };
}
