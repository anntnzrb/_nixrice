{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.desktop.discord;
in
{
  options.liberion.desktop.discord = {
    enable = lib.mkEnableOption "discord";
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.discord ];
  };
}
