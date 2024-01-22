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
  options.liberion.common.xorg = {
    enable = mkEnableOption "xorg defaults";

    autoStart = mkOption {
      type = with types; listOf str;
      default = [ ];
    };

    autorandr = {
      enable = mkEnableOption "use autorandr?";
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
