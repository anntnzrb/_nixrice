{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.liberion) mkOpt' mkOptBool';

  cfg = config.liberion.desktop.sxhkd;
in {
  options.liberion.desktop.sxhkd = {
    enable = mkOptBool' false;

    keybinds = with lib.types; mkOpt' (attrsOf (nullOr (oneOf [str path]))) {};
  };

  config = lib.mkIf cfg.enable {
    services.sxhkd = {
      enable = true;
      extraOptions = ["-m 1"];
      keybindings =
        {
          "super + Return ; {Return}" = "$TERMINAL {_}";
          "super + d ; {d}" = "{rofi -show run}";

          "super + w ; {f,w}" = "{$FILE,$BROWSER}";
          "super + Escape ; {slash,x}" = "{pkill -USR1 'sxhkd', pkill -15 'X'}";

          "Print" = "\{ flameshot & \} && sleep 0.5s && flameshot gui";

          "XF86AudioMute" = "pamixer -t";
          "XF86Audio{Lower,Raise}Volume" = "pamixer -{d,i} 5";

          "XF86MonBrightness{Down,Up}" = "brightnessctl set {2%-,+2%}";
        }
        // cfg.keybinds;
    };
  };
}
