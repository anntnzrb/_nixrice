{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.flameshot;
in {
  options.liberion.desktop.flameshot = {
    enable = mkOptBool' false;
  };

  config = lib.mkIf cfg.enable {
    services.flameshot = {
      enable = true;
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
  };
}
