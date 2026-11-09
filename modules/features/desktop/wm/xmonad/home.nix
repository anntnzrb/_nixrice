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

  cfg = config.liberion.desktop.wm.xmonad;
  bemenuRun = lib.getExe' pkgs.bemenu "bemenu-run";
  startx = lib.getExe' pkgs.xorg.xinit "startx";
  xmonad = config.xsession.windowManager.command;
  xmonadConfig = pkgs.runCommand "xmonad-config" { } ''
    cp -R ${./xmonad} "$out"
    chmod u+w "$out/xmonad.hs"
    substituteInPlace "$out/xmonad.hs" \
      --replace-fail '@bemenuRun@' '${bemenuRun}' \
      --replace-fail '@xmonad@' '${xmonad}'
  '';
in
{
  imports = [
    inputs.self.homeModules.xsession
    inputs.self.homeModules.session
  ];

  options.liberion.desktop.wm.xmonad = {
    compositor.picom.enable = mkOptDisabled';
    autoStart = mkOpt' (listOf str) [ ];
  };

  config = {
    liberion.desktop.xsession.picom.enable = cfg.compositor.picom.enable;

    xsession = {
      initExtra = lib.liberion.xorg.mkAutostartScript cfg.autoStart;
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
      };
    };

    xdg.configFile.xmonad = {
      enable = true;
      source = xmonadConfig;
      target = "xmonad";
      recursive = true;
    };

    home = {
      shellAliases = {
        wm-exec-xmonad = "${startx} ~/${config.xsession.scriptPath}";
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
