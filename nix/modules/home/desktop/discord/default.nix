{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.discord;
in {
  options.liberion.desktop.discord = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.discord];
  };
}
