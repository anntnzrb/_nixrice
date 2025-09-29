{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptDisabled'
    on
    ;
  inherit (lib.types)
    listOf
    str
    ;

  cfg = config.${namespace}.desktop.window-managers.xorg.awesomewm;

  parseAutoStartList = xs: lib.concatStringsSep "\n" (map (x: x + " &") xs);
in
{
  options.${namespace}.desktop.window-managers.xorg.awesomewm = {
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
    ${namespace}.common.xorg = on // {
      inherit (cfg.compositor) picom;
    };

    xsession = {
      windowManager.awesome = on;
      initExtra = parseAutoStartList cfg.autoStart;
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
