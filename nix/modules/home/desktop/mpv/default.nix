{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.mpv;
in
{
  options.liberion.desktop.mpv = with lib.liberion; {
    enable = mkOptBool';
  };
  config = lib.mkIf cfg.enable {
    programs.mpv = {
      enable = true;
      bindings =
        let
          # Seek {for,back}-ward by a number of seconds
          # seek: number -> string
          seek = val: "no-osd seek ${toString val} exact";

          # {In,De}-crease volume by a percentage value
          # speed: number -> string
          speed = val: "add speed ${toString val}";

          # {In,De}-crease volume by a percentage value
          # vol: number -> string
          vol = val: "add volume ${toString val}";

          # Disable a keybinding
          # disabled -> string
          disabled = "noop";
        in
        {
          "LEFT" = seek (-5);
          "RIGHT" = seek 5;
          "Ctrl+LEFT" = seek (-60);
          "Ctrl+RIGHT" = seek 60;

          "[" = disabled;
          "]" = disabled;
          "<" = speed (-0.05);
          ">" = speed 0.05;

          "DOWN" = vol (-2);
          "UP" = vol 2;
          "m" = "cycle mute";

          "q" = "quit-watch-later";
        };
    };
  };
}
