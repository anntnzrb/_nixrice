{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.xorg.awesomewm;
in
{
  options.liberion.desktop.window-managers.xorg.awesomewm = with lib; {
    enable = lib.mkEnableOption "awesome";

    # -------------------------------------------------------------------------
    # xorg
    # -------------------------------------------------------------------------

    autoStart = mkOption {
      type = with types; listOf str;
      default = [ ];
    };

    autorandr = {
      enable = lib.mkEnableOption "use autorandr?";
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
