{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.common.xorg;
in
{
  options.liberion.common.xorg = with lib.liberion; with lib.types; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    xsession = {
      enable = true;
      profilePath = ".config/xorg/xprofile-hm";
      scriptPath = ".config/xorg/xsession-hm";

      initExtra = with config.liberion.home.keyboard; ''
        ${lib.getExe pkgs.xorg.xset} r rate ${toString autoRepeatDelay} ${toString autoRepeatInterval}
      '';
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
        xorg.xprop
      ];
    };
  };
}
