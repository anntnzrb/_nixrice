{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.discord;
in
{
  options.${namespace}.desktop.discord = with lib.${namespace}; {
    enable = mkOptBool';
  };
  config = lib.mkIf cfg.enable { home.packages = [ pkgs.discord ]; };
}
