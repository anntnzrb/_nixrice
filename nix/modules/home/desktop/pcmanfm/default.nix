{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.pcmanfm;
in {
  options.liberion.desktop.pcmanfm = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.pcmanfm];

    xdg.configFile = {
      "pcmanfm" = {
        enable = true;
        source = ./config/pcmanfm;
        target = "pcmanfm";
        recursive = true;
      };
    };
  };
}
