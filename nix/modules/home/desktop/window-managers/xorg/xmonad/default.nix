{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.liberion.desktop.window-managers.xorg.xmonad;

  parseAutoStartList = xs: builtins.concatStringsSep "\n" (map (x: x + " &") xs);
in
{
  options.liberion.desktop.window-managers.xorg.xmonad =
    with lib.liberion;
    with lib.types;
    {
      enable = mkOptBool';

      compositor = {
        picom.enable = mkOptBool';
      };

      autoStart = mkOpt' (listOf str) [ ];
    };

  config = lib.mkIf cfg.enable {
    liberion.common.xorg = {
      enable = true;
      inherit (cfg.compositor) picom;
    };

    xsession = {
      initExtra = parseAutoStartList cfg.autoStart;
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
