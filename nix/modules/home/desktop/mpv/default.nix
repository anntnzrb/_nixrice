{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.mpv;
in {
  options.liberion.desktop.mpv = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    programs.mpv = {
      enable = true;
      bindings = {
        "LEFT" = "seek -10 exact";
        "RIGHT" = "seek  10 exact";
        "Shift+LEFT" = "no-osd seek  -5 exact";
        "Shift+RIGHT" = "no-osd seek   5 exact";
        "Ctrl+LEFT" = "no-osd seek -60 exact";
        "Ctrl+RIGHT" = "no-osd seek  60 exact";

        "[" = "add speed -0.05";
        "]" = "add speed  0.05";

        "DOWN" = "add volume -2";
        "UP" = "add volume  2";
        "m" = "cycle mute";

        "q" = "quit-watch-later";
      };
    };
  };
}
