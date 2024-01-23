{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.common.xorg;

  parseAutoStartList = xs: builtins.concatStringsSep "\n" (map (x: x + " &") xs);

in
with lib;
{
  options.liberion.common.xorg = with lib.liberion; with lib.types; {
    enable = mkOptBool';

    autoStart = mkOpt' (listOf str) [ ];

    autorandr = {
      enable = mkOptBool';
    };
  };

  config = mkIf cfg.enable {
    xsession = {
      enable = true;

      initExtra = parseAutoStartList (cfg.autoStart ++ optional cfg.autorandr.enable "autorandr -c");
      profilePath = ".config/xprofile-hm";
      scriptPath = ".config/xsession-hm";
    };

    home.packages = [
      (pkgs.writeShellApplication {
        name = "wm-exec";
        text = "startx ~/${config.xsession.scriptPath}";
      })
    ];
  };
}
