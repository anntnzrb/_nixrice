{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.wm.awesomewm;
  startx = lib.getExe' pkgs.xorg.xinit "startx";
in
{
  imports = with inputs.self.homeModules; [
    session
    xsession
  ];

  options.liberion.desktop.wm.awesomewm = {
    autoStart = mkOpt' (listOf str) [ ];
  };

  config = {
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
        wm-exec-awesome = "${startx} ~/${config.xsession.scriptPath}";
      };

      packages = with pkgs; [
        lua
        stylua
        lua-language-server
      ];
    };
  };
}
