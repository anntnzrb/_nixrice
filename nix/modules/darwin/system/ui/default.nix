{ config
, lib
, namespace
, ...
}:
let
  cfg = config.${namespace}.system.ui;
in
{
  options.${namespace}.system.ui = with lib.${namespace}; {
    enable = mkOptBool';

    menuBar = {
      hide = mkOptBool';
    };
  };

  config = {
    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";

        # menu bar
        _HIHideMenuBar = cfg.menuBar.hide;
      };
    };
  };
}
