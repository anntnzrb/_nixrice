{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.wayland.sway;
in
with lib; {
  options.liberion.desktop.window-managers.wayland.sway = with lib.liberion; with types; {
    enable = mkOptBool';

    keyboard = {
      layout = mkOpt' str "us";
      variant = mkOpt' str "altgr-intl";
      repeat_delay = mkOpt' ints.unsigned 300;
      repeat_rate = mkOpt' ints.unsigned 80;
    };

    autoStart = mkOpt' (listOf str) [ ];

    modifier = mkOpt' str "Mod4";

    output = mkOpt' (attrsOf (attrsOf str)) { };
  };

  config = mkIf cfg.enable {
    home = {
      shellAliases = {
        sway = "printf 'Do not use this command. To launch sway use the 'wm-exec-sway' wrapper.\n' >&2";
        wm-exec-sway = "command sway";
      };

      packages = [
        # fonts
        pkgs.iosevka-comfy.comfy
      ];
    };

    wayland.windowManager.sway = {
      enable = true;
      xwayland = true;

      wrapperFeatures = {
        gtk = true;
      };

      config = rec {
        inherit (cfg) output;
        inherit (cfg) modifier;

        up = "k";
        down = "j";
        right = "l";
        left = "h";

        startup = [ ] ++ map
          (cmd: {
            command = cmd;
          })
          cfg.autoStart;

        colors = {
          background = "#1C1B19";

          focused = {
            background = "#3A3A3A";
            border = "#918175";
            childBorder = "#918175";
            indicator = "#FBB829";
            text = "#FBB829";
          };

          unfocused = {
            background = "#262626";
            border = "#262626";
            childBorder = "#262626";
            indicator = "#262626";
            text = "#918175";
          };

          focusedInactive = {
            background = "#3A3A3A";
            border = "#3A3A3A";
            childBorder = "#3A3A3A";
            indicator = "#3A3A3A";
            text = "#918175";
          };

          placeholder = {
            background = "#121212";
            border = "#3A3A3A";
            childBorder = "#3A3A3A";
            indicator = "#3A3A3A";
            text = "#918175";
          };

          urgent = {
            background = "#262626";
            border = "#EF2F27";
            childBorder = "#EF2F27";
            indicator = "#EF2F27";
            text = "#EF2F27";
          };
        };

        fonts = {
          names = [ "Iosevka Comfy Motion" ];
          style = "SemiLight Italic";
          size = 11.0;
        };

        window = {
          titlebar = true;
          border = 3;
        };

        bars = [
          {
            inherit fonts;

            # TODO: check if this was solved. i3status-rs should generate the proper file.
            # statusCommand = "i3status-rs ${config.xdg.configHome}/i3status-rust/config-default.toml";
            command = "waybar";
            position = "top";
            trayOutput = "*";

            colors = rec {
              background = "#1C1B19";
              focusedBackground = background;

              activeWorkspace = {
                background = "#3A3A3A";
                border = "#3A3A3A";
                text = "#918175";
              };

              focusedWorkspace = {
                background = "#3A3A3A";
                border = "#918175";
                text = "#FBB829";
              };

              inactiveWorkspace = {
                background = "#262626";
                border = "#3A3A3A";
                text = "#918175";
              };

              urgentWorkspace = {
                background = "#E02C6D";
                border = "#E02C6D";
                text = "#FCE8C3";
              };
            };
          }
        ];

        keybindings =
          let
            mod = modifier;
            modShift = "${mod}+Shift";
            modAlt = "${mod}+Alt";
            numWorkspaces = 9;

            genFocusMoveBinds = bind: {
              "${mod}+${bind.key}" = "focus ${bind.dir}";
              "${modShift}+${bind.key}" = "move ${bind.dir}";
            };
            genWorkspaceBinds = i:
              let ws = toString i; in {
                "${mod}+${ws}" = "workspace number ${ws}";
                "${modShift}+${ws}" = "move container to workspace number ${ws}";
              };
          in
          with config.home.sessionVariables; {
            # TODO: mv
            "${mod}+Return" = "exec ${TERMINAL}";
            "${mod}+d" = "exec bemenu-run";

            "${modShift}+q" = "kill";
            "${modAlt}+r" = "reload";
            "${modAlt}+q" = "exit";

            "${modShift}+space" = "floating toggle";
            "${modShift}+f" = "fullscreen toggle";
          } // builtins.foldl' (a: b: a // b) { } (
            map genFocusMoveBinds [
              { key = "h"; dir = "left"; }
              { key = "j"; dir = "down"; }
              { key = "k"; dir = "up"; }
              { key = "l"; dir = "right"; }

              { key = "Left"; dir = "left"; }
              { key = "Down"; dir = "down"; }
              { key = "Up"; dir = "up"; }
              { key = "Right"; dir = "right"; }
            ] ++
            map genWorkspaceBinds (builtins.genList (x: x + 1) numWorkspaces)
          );

        gaps = {
          inner = 10;
        };

        input = {
          "*" = {
            # keyboard
            xkb_model = cfg.keyboard.layout;
            xkb_layout = cfg.keyboard.layout;
            xkb_variant = cfg.keyboard.variant;
            repeat_delay = toString cfg.keyboard.repeat_delay;
            repeat_rate = toString cfg.keyboard.repeat_rate;

            # mouse/touchpad
            accel_profile = "flat";
            drag = "true";
            dwt = "true";
            natural_scroll = "false";
            scroll_method = "two_finger";
            tap = "true";
          };
        };

        seat = {
          "*" = {
            hide_cursor = "2000";
          };
        };

        menu = "";
        terminal = "";
        modes = { };
        workspaceLayout = "default";
        workspaceAutoBackAndForth = false;
      };
    };

    programs.waybar = {
      enable = true;

      style = builtins.readFile ./style.css;

      settings = {
        default = {
          position = "top";

          modules-left = [ "sway/workspaces" ];
          modules-center = [ ];
          modules-right = [ "cpu" "memory" "tray" "clock" ];

          clock = {
            format = "  {:%a, %d/%m %R}";
            tooltip-format = "{:%Y-%m-%d}";
          };

          cpu = {
            interval = 10;
            format = "  {usage}%";
          };

          memory = {
            interval = 10;
            format = "  {percentage}%";
          };

          tray = {
            spacing = 5;
          };
        };
      };
    };

    programs.i3status-rust = {
      enable = false;

      bars = {
        default = {
          icons = "material-nf";
          theme = "srcery";

          blocks = [
            {
              block = "battery";
              missing_format = "";
            }
            {
              block = "backlight";
              missing_format = "";
            }
            {
              block = "cpu";
              interval = 10;
              format = " $icon $utilization ";
            }
            {
              block = "memory";
              format = " $icon $mem_used_percents ";
              interval = 10;
            }
            {
              block = "time";
              format = " $timestamp.datetime(f:'%a, %d/%m @ %R') ";
              interval = 60;
            }
          ];
        };
      };
    };
  };
}
