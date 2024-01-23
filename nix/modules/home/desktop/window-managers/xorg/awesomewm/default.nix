{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.xorg.awesomewm;
in
{
  options.liberion.desktop.window-managers.xorg.awesomewm = with lib.liberion; with lib.types; {
    enable = mkOptBool';

    # -------------------------------------------------------------------------
    # xorg
    # -------------------------------------------------------------------------

    autoStart = mkOpt' (listOf str) [ ];

    autorandr = {
      enable = mkOptBool';
    };
  };

  config = lib.mkIf cfg.enable {
    liberion.common.xorg = {
      enable = true;
      inherit (cfg) autorandr autoStart;
    };

    xsession.windowManager.awesome.enable = true;

    xdg.configFile = {
      "awesome" = {
        enable = true;
        source = ./config;
        target = "awesome";
        recursive = true;
      };
    };
  };
}
