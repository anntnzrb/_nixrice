{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.xorg.awesomewm;
in
{
  options.liberion.desktop.window-managers.xorg.awesomewm = with lib.liberion; with lib.types; {
    enable = mkOptBool';

    autoStart = mkOpt' (listOf str) [ ];
  };

  config = lib.mkIf cfg.enable {
    liberion.common.xorg = {
      enable = true;
      inherit (cfg) autoStart;

      picom.enable = false;
    };

    home = {
      shellAliases = {
        wm-exec-awesome = "command startx ~/${config.xsession.scriptPath}";
      };

      packages = with pkgs; [
        lua
        stylua
        lua-language-server
      ];
    };

    xsession.windowManager.awesome.enable = true;

    xdg.configFile = {
      awesomewm = {
        enable = true;
        source = ./awesome;
        target = "awesome";
        recursive = true;
      };
    };
  };
}
