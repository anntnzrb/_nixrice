{ config, namespace, ... }:
let
  _cfg = config.${namespace}.system.ui;
in
{
  config = {
    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";

        # menu bar
        _HIHideMenuBar = true;
      };
    };
  };
}
