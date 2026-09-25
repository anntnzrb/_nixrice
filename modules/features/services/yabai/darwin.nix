{ lib, inputs, ... }:
let
  mkRule =
    pattern:
    "yabai -m rule --add ${
      lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "${k}=${v}") pattern)
    } manage=off";
in
{
  imports = [ inputs.self.darwinModules.skhd ];

  services.yabai = {
    enable = true;

    config = {
      layout = "bsp";
      split_ratio = 0.5;
      focus_follows_mouse = "autofocus";

      # mouse
      mouse_modifier = "fn";
      mouse_follows_focus = "on"; # warp mouse?
      mouse_action1 = "move"; # mod + LMB
      mouse_action2 = "resize"; # mod + RMB

      # gaps
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 15;
      right_padding = 15;
      window_gap = 15;
    };

    extraConfig =
      let
        # windows yabai leaves floating
        unmanaged = [
          { app = "^System Settings$"; }
          { app = "^System Information$"; }
          { app = "^System Preferences$"; }
          { title = "Preferences$"; }
          { title = "Settings$"; }
          { app = "^Finder$"; }
          { app = "^Terminal$"; }
          { app = "^Calculator$"; }
          { app = "^Notes$"; }
          { app = "^Weather$"; }
          { app = "^Calendar$"; }
          { app = "^Clock$"; }
          { app = "^Alacritty$"; }
          { app = "^Bitwarden$"; }
          { app = "^ChatGPT$"; }
          { app = "^WhatsApp$"; }
        ];
      in
      ''
        # rules
        ${lib.concatMapStringsSep "\n" mkRule unmanaged}
      '';
  };

  liberion.services.skhd.keybindings = {
    "alt - k" = "yabai -m window --focus north";
    "alt - l" = "yabai -m window --focus east";
    "alt - j" = "yabai -m window --focus south";
    "alt - h" = "yabai -m window --focus west";
  };
}
