{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.window-manager.bspwm;
in {
  options.liberion.desktop.window-manager.bspwm = {
    enable = mkOptBool' false;
  };

  config = lib.mkIf cfg.enable {
    xsession.enable = true;

    xsession.windowManager.bspwm = {
      enable = true;
      alwaysResetDesktops = true;

      monitors = {
        HDMI-0 = [
          "I"
          "II"
          "III"
          "IV"
          "V"
          "VI"
          "VII"
          "VIII"
          "IX"
        ];
      };

      startupPrograms = [
      ];
    };

    liberion.desktop.sxhkd = {
      enable = true;
      keybinds = {
        "super + {_,shift +} {1-9}" = "bspc {desktop -f,node -d} '^{1-9}'";
      };
    };

    home.packages = [
      (pkgs.writeShellApplication {
        name = "bsp-start";
        text = "startx ${config.xdg.configHome}/xsession-hm";
      })
    ];
  };
}
