{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.system.ui;
in
{
  options.${namespace}.system.ui = {
    enable = mkOptBool';

    menuBar = {
      hide = mkOptBool';
    };
  };

  config = {
    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleFontSmoothing = 2;

        # menu bar
        _HIHideMenuBar = cfg.menuBar.hide;
      };
    };
  };
}
