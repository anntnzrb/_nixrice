import ../../../toggle.nix "shared.xorg" (
  {
    lib,
    pkgs,
    config,
    ...
  }:
  {
    xsession = {
      enable = true;
      profilePath = ".config/xorg/xprofile-hm";
      scriptPath = ".config/xorg/xsession-hm";

      initExtra = with config.liberion.home.keyboard; ''
        ${lib.getExe pkgs.xset} r rate ${toString autoRepeatDelay} ${toString autoRepeatInterval}
      '';
    };

    home = {
      sessionVariables = {
        XAUTHORITY = "${config.xdg.stateHome}/.Xauthority";
      };
      shellAliases = {
        startx = "printf 'Do not use this command. Use the appropriate wrapper for launching the graphic environment.\n' >&2";
      };

      packages = with pkgs; [
        xclip
        arandr
        xorg.xev
        xprop
      ];
    };
  }
)
