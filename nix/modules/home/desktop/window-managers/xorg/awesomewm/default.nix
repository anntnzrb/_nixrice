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
    ${namespace}.shared.xorg = on // {
      inherit (cfg.compositor) picom;
    };

    xsession = {
      windowManager.awesome = on;
      initExtra = lib.${namespace}.xorg.mkAutostartScript cfg.autoStart;
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
