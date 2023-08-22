{
  services.sxhkd = {
    enable = true;
    keybindings = {
      "super + Return ; {Return}" = "$TERMINAL {_}";
      "super + d ; {d}" = "{rofi -show run}";

      "super + w ; {f,w}" = "{$FILE,$BROWSER}";
      "super + Escape ; {slash,x}" = "{pkill -USR1 'sxhkd', pkill -15 'X'}";

      "XF86AudioMute" = "pamixer -t";
      "XF86Audio{Lower,Raise}Volume" = "pamixer -{d,i} 5";

      "XF86MonBrightness{Down,Up}" = "brightnessctl set {2%-,+2%}";

      "Print" = "sshootr";
    };
  };
}
