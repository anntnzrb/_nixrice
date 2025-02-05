{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.desktop.flameshot;
in
{
  options.${namespace}.desktop.flameshot = {
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
