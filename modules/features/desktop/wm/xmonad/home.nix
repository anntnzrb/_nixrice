{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.window-managers.xorg.xmonad;
in
{
  imports = [
    inputs.self.homeModules.xsession
    # $TERMINAL is spawned by the M-<Return> binding in xmonad.hs
    inputs.self.homeModules.session
  ];

  options.liberion.desktop.window-managers.xorg.xmonad = {
    compositor.picom.enable = mkOptDisabled';
    autoStart = mkOpt' (listOf str) [ ];
  };

  config = {
    liberion.shared.xorg.picom.enable = cfg.compositor.picom.enable;

    xsession = {
      initExtra = lib.liberion.xorg.mkAutostartScript cfg.autoStart;
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
    };

    xdg.configFile = {
      xmonad = {
        enable = true;
        source = ./xmonad;
        target = "xmonad";
        recursive = true;
      };
    };

    home = {
      shellAliases = {
        wm-exec-xmonad = "command startx ~/${config.xsession.scriptPath}";
      };

      packages = with pkgs; [
        haskell-language-server
        ormolu
        hlint

        (haskellPackages.ghcWithPackages (hpkgs: [
          hpkgs.xmonad
          hpkgs.xmonad-contrib
          hpkgs.xmonad-extras
        ]))
      ];
    };
  };
}
