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
    programs.firefox.profiles.default.settings =
      firefoxLib.privacyToSettings cfg.privacy;
  };
}
