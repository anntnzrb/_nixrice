{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.desktop.flameshot;
in
{
  options.liberion.desktop.flameshot = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.flameshot = {
      inherit (cfg) enable;
      settings = {
        General = {
          autoCloseIdleDaemon = true;
          saveAsFileExtension = "png";
          savePath = "${config.xdg.userDirs.pictures}";
          savePathFixed = true;
          showMagnifier = true;
          uploadHistoryMax = 50;
          uploadWithoutConfirmation = true;
        };
      };
    };

    services.sxhkd = {
      keybindings = {
        "Print" = "flameshot gui";
      };
    };
  };
}
