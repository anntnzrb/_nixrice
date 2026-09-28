{ pkgs, ... }: {
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
    ];

    config = {
      osd-bar = false;
      border = false;
    };

    bindings =
      let
        seek = val: "no-osd seek ${toString val} exact";

        speed = val: "add speed ${toString val}";

        vol = val: "add volume ${toString val}";

        disabled = "noop";
      in
      {
        "LEFT" = seek (-5);
        "RIGHT" = seek 5;
        "Ctrl+LEFT" = seek (-60);
        "Ctrl+RIGHT" = seek 60;

        "[" = disabled;
        "]" = disabled;
        "<" = speed (-5.0e-2);
        ">" = speed 5.0e-2;

        "DOWN" = vol (-2);
        "UP" = vol 2;
        "m" = "cycle mute";

        "q" = "quit-watch-later";
      };
  };
}
