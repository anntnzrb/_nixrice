{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled' on;
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.window-managers.xorg.xmonad;
in
{
  options.liberion.desktop.window-managers.xorg.xmonad = {
    enable = mkOptDisabled';
    compositor.picom.enable = mkOptDisabled';
    autoStart = mkOpt' (listOf str) [ ];
  };

  config = lib.mkIf cfg.enable {
    liberion.shared.xorg = on // {
      inherit (cfg.compositor) picom;
    };

    xsession = {
      initExtra = lib.liberion.xorg.mkAutostartScript cfg.autoStart;
      windowManager.xmonad = on // {
        enableContribAndExtras = true;
      };
    };

    xdg.configFile = {
      xmonad = on // {
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
