{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.system.ui;
in
{
  options.${namespace}.system.ui = {
    enable = mkOptDisabled';

    menuBar = {
      hide = mkOptDisabled';
    };
  };

  config = lib.mkIf cfg.enable {
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
