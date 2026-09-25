{
  lib,
  config,
  firefoxLib,
  ...
}:
let
  cfg = config.liberion.desktop.browsers.firefox;
in
{
  config = lib.mkIf cfg.enable {
    programs.firefox.profiles.default = {
      userChrome = firefoxLib.uiToUserChrome cfg.ui;
      settings = firefoxLib.uiToSettings cfg.ui;
    };
  };
}
