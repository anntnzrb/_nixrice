{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.common.xorg;
in
{
  options.liberion.common.xorg = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    xsession = {
      enable = true;
      profilePath = ".config/xorg/xprofile-hm";
      scriptPath = ".config/xorg/xsession-hm";
    };

    home = {
      sessionVariables = {
        XAUTHORITY = "${config.xdg.stateHome}/.Xauthority";
      };
      shellAliases = {
        startx = "printf 'Do not use this command. Use the appropiate wrapper for launching the graphic environment.\n' >2&1";
      };

      packages = with pkgs; [
        xclip
        arandr
        xorg.xev
      ];
    };
  };
}
