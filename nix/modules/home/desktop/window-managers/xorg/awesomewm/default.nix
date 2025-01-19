{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.window-managers.xorg.awesomewm;

  parseAutoStartList = xs: builtins.concatStringsSep "\n" (map (x: x + " &") xs);
in
{
  options.${namespace}.desktop.window-managers.xorg.awesomewm =
    with lib.${namespace};
    with lib.types;
    {
      enable = mkOptBool';

      compositor = {
        picom = {
          enable = mkOptBool';
          vSync = mkOptBool';
        };
      };

      autoStart = mkOpt' (listOf str) [ ];
    };

  config = lib.mkIf cfg.enable {
    ${namespace}.common.xorg = {
      enable = true;
      inherit (cfg.compositor) picom;
    };

    xsession = {
      windowManager.awesome.enable = true;
      initExtra = parseAutoStartList cfg.autoStart;
    };

    xdg.configFile = {
      awesomewm = {
        enable = true;
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
