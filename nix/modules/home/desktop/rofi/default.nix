{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.rofi;
in {
  options.liberion.desktop.rofi = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      font = "Iosevka 12";
      location = "center";
      terminal = "${config.home.sessionVariables.TERMINAL}";
    };

    home.packages = [pkgs.iosevka];
  };
}
