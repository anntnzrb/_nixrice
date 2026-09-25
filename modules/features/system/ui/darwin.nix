{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.system.ui;
in
{
  options.liberion.system.ui = {
    menuBar = {
      hide = mkOptDisabled';
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
