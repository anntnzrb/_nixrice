{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.liberion.desktop.discord;
in
{
  options.liberion.desktop.discord = with lib.liberion; {
    enable = mkOptBool';
  };
  config = lib.mkIf cfg.enable { home.packages = [ pkgs.discord ]; };
}
