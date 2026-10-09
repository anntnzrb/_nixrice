{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.wm.awesomewm;
in
{
  imports = with inputs.self.homeModules; [
    session
    xsession
  ];

  options.liberion.desktop.wm.awesomewm = {
    compositor = {
      picom = {
        enable = mkOptDisabled';
        vSync = mkOptDisabled';
      };
    };

    autoStart = mkOpt' (listOf str) [ ];
  };

  config = {
    liberion.desktop.xsession.picom = {
      inherit (cfg.compositor.picom) enable vSync;
    };

    xsession = {
      windowManager.awesome.enable = true;
      initExtra = lib.liberion.xorg.mkAutostartScript cfg.autoStart;
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
