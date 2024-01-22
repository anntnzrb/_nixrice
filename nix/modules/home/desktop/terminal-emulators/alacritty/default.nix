{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.desktop.terminal-emulators.alacritty;
in
{
  options.liberion.desktop.terminal-emulators.alacritty = {
    enable = lib.mkEnableOption "alacritty";
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        live_config_reload = true;
        working_directory = "None";
        blink_interval = 300;
        blink_timeout = 0;
        unfocused_hollow = true;
        vi_mode_style = "Block";

        font = {
          size = 15.0;
          builtin_box_drawing = false;

          normal = {
            family = "Fantasque Sans Mono";
            style = "Regular";
          };

          bold = {
            family = "Fantasque Sans Mono";
            style = "Bold";
          };

          italic = {
            family = "Fantasque Sans Mono";
            style = "Italic";
          };

          bold_italic = {
            family = "Fantasque Sans Mono";
            style = "Bold Italic";
          };
        };

        window = {
          opacity = 0.9;
          dynamic_title = true;
          decorations_theme_variant = "None";
          resize_increments = true;

          class = {
            instance = "Alacritty";
            general = "Alacritty";
          };
        };

        cursor = {
          style = {
            shape = "Beam";
            blinking = "Always";
          };
        };

        scrolling = {
          history = 10000;
          multiplier = 1;
        };

        key_bindings = [
          { key = "C"; mods = "Control|Shift"; action = "Copy"; }
          { key = "V"; mods = "Control|Shift"; action = "Paste"; }
        ];

        mouse_bindings = [
          { mouse = "Right"; action = "ExpandSelection"; }
          { mouse = "Middle"; action = "PasteSelection"; }
        ];
      };
    };

    home.packages = with pkgs; [
      fantasque-sans-mono
    ];
  };
}
