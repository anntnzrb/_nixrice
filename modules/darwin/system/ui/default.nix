{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.system.ui;
in
{
  options.liberion.system.ui = {
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
