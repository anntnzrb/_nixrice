{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled' on;
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.window-managers.xorg.awesomewm;
in
{
  options.liberion.desktop.window-managers.xorg.awesomewm = {
    enable = mkOptDisabled';

    compositor = {
      picom = {
        enable = mkOptDisabled';
        vSync = mkOptDisabled';
      };
    };

    autoStart = mkOpt' (listOf str) [ ];
  };

  config = lib.mkIf cfg.enable {
    liberion.shared.xorg = on // {
      inherit (cfg.compositor) picom;
    };

    xsession = {
      windowManager.awesome = on;
      initExtra = lib.liberion.xorg.mkAutostartScript cfg.autoStart;
    };

    xdg.configFile = {
      awesomewm = on // {
        source = ./awesome;
        target = "awesome";
        recursive = true;
      };
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
  };
}
