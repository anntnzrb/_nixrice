{ config
, namespace
, ...
}:
let
  _cfg = config.${namespace}.darwin.system.ui;
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
