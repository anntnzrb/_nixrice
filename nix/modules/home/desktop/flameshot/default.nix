{ lib
, config
, ...
}:
let
  cfg = config.liberion.desktop.flameshot;
in
{
  options.liberion.desktop.flameshot = {
    enable = lib.mkEnableOption "flameshot";
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
