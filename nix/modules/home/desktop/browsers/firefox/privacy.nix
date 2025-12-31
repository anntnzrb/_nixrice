{
  lib,
  config,
  namespace,
  ...
}:
let
  firefoxLib = import ./lib.nix { inherit lib; };
  cfg = config.${namespace}.desktop.browsers.firefox;
in
{
  config = lib.mkIf cfg.enable {
    programs.firefox.profiles.default.settings =
      firefoxLib.privacyToSettings cfg.privacy;
  };
}
