{ config
, lib
, pkgs
, namespace
, ...
}:
let
  cfg = config.${namespace}.desktop.terminal-emulators.alacritty;
in
with lib.${namespace}; {
  options.${namespace}.desktop.terminal-emulators.alacritty = {
    enable = mkOptBool';

    package = {
      install = mkOptEnabled';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      # HACK: use git instead of null pkg
      package = with pkgs; if cfg.package.install then alacritty else git;

      settings = {
        live_config_reload = true;
        working_directory = "None";

        font =
          let
            _fantasque = "Fantasque Sans Mono";
            codeNewRoman = "CodeNewRoman Nerd Font";
          in
          {
            size = 15.0;
            builtin_box_drawing = false;

            normal = {
              family = codeNewRoman;
              style = "Regular";
            };

            bold = {
              family = codeNewRoman;
              style = "Bold";
            };

            italic = {
              family = codeNewRoman;
              style = "Italic";
            };

            bold_italic = {
              family = codeNewRoman;
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

    home.packages = with pkgs; [
      fantasque-sans-mono
    ];
  };
}
