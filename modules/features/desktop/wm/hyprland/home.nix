{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.wm.hyprland;
in
{
  imports = [ inputs.self.homeModules.session ];

  options.liberion.desktop.wm.hyprland = {
    monitor = mkOpt' (listOf str) [ ",preferred,auto,1" ];
    autoStartApps = mkOpt' (listOf str) [ ];
    waybar.enable = mkOptDisabled';
  };

  config = {
    home = {
      shellAliases = {
        Hyprland = "printf 'Do not use this command. To launch Hyprland use the 'wm-exec-hypr' wrapper.\n' >&2";
        wm-exec-hypr = "\\Hyprland";
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;

      settings = {
        "$mod" = "SUPER";
        "$TERMINAL" = lib.getExe config.liberion.desktop.session.apps.terminal;

        inherit (cfg) monitor;

        exec-once = cfg.autoStartApps ++ (lib.optional cfg.waybar.enable "waybar");

        input = {
          follow_mouse = 1;
          sensitivity = 0;
        };

        general = {
          layout = "master";
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
        };

        decoration = {
          rounding = 6;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.15;
          };
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };
        };

        animations.enabled = true;

        gesture = "3, horizontal, workspace";

        misc = {
          disable_hyprland_logo = 0;
          disable_splash_rendering = 0;
          force_default_wallpaper = 0;
        };

        master = {
          new_status = "slave";
          mfact = 0.5;
          orientation = "left";
        };

        bind =
          lib.concatMap (ws: [
            "$mod, ${ws}, workspace, ${ws}"
            "$mod SHIFT, ${ws}, movetoworkspace, ${ws}"
          ]) (map toString (lib.range 1 9))
          ++ [
            "$mod SHIFT, Q, killactive,"
            "$mod ALT, Q, exit,"
            "$mod SHIFT, SPACE, togglefloating,"
            "$mod, D, exec, wofi --show run"
            "$mod, Return, exec, $TERMINAL"
          ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
      };
    };

    programs.waybar = lib.mkIf cfg.waybar.enable {
      inherit (cfg.waybar) enable;

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;

          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [
            "tray"
            "clock"
          ];

          "clock" = {
            format = "{:%H:%M}  ";
            format-alt = "{:%A; %B %d, %Y (%R)}  ";
            actions = {
              on-click-right = "mode";
            };
          };

          "hyprland/workspaces" = {
            active-only = false;
            all-outputs = true;
          };
        };
      };
    };
  };
}
