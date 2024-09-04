{ config
, lib
, namespace
, ...
}:
let
  cfg = config.${namespace}.desktop.terminal-emulators.alacritty;
in
with lib.${namespace}; {
  options.${namespace}.desktop.terminal-emulators.alacritty = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        live_config_reload = true;
        working_directory = "None";

        font =
          let
            _fantasque = "Fantasque Sans Mono";
            _mononoki = "mononoki";
            _codeNewRoman = "CodeNewRoman Nerd Font";
            firaCode-mono = "FiraCode Nerd Font Mono";
          in
          {
            size = 14.0;
            builtin_box_drawing = false;

            normal = {
              family = firaCode-mono;
              style = "Regular";
            };

            bold = {
              family = firaCode-mono;
              style = "Bold";
            };

            italic = {
              family = firaCode-mono;
              style = "Italic";
            };

            bold_italic = {
              family = firaCode-mono;
              style = "Bold Italic";
            };
          };

        window = {
          opacity = 0.9;
          dynamic_title = true;
          decorations_theme_variant = "None";
          resize_increments = true;
        };

        cursor = {
          style = {
            shape = "Beam";
            blinking = "Always";
          };

          blink_interval = 300;
          blink_timeout = 0;
          unfocused_hollow = true;
        };

        scrolling = {
          history = 10000;
          multiplier = 1;
        };

        keyboard.bindings = [
          # copy/paste
          { key = "C"; mods = "Control|Shift"; action = "Copy"; }
          { key = "V"; mods = "Control|Shift"; action = "Paste"; }

          # search
          { key = "/"; mods = "Control"; action = "SearchForward"; }
        ];

        mouse = {
          hide_when_typing = true;

          bindings = [
            { mouse = "Right"; action = "ExpandSelection"; }
            { mouse = "Middle"; action = "PasteSelection"; }
          ];
        };
      };
    };
  };
}
