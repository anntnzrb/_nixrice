{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.flameshot;
in
{
  options.${namespace}.desktop.flameshot = with lib.${namespace}; {
    enable = mkOptBool';
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

    services.sxhkd = {
      keybindings = {
        "Print" = "flameshot gui";
      };
    };
  };
}
