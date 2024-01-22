{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.wayland.hyprland;
in
{
  options.liberion.desktop.window-managers.wayland.hyprland = with lib; {
    enable = mkEnableOption "hyprland";
    keyboard = {
      layout = mkOption {
        type = types.str;
        default = "us";
      };

      variant = mkOption {
        type = types.str;
        default = "altgr-intl";
      };
    };

    monitor = mkOption {
      type = with types; listOf str;
      default = [ ",preferred,auto,1" ];
    };

    autoStartApps = mkOption {
      type = with types; listOf str;
      default = [ ];
    };

    waybar = {
      enable = mkEnableOption "waybar";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      shellAliases = {
        Hyprland = "printf 'Do not use this command. To launch Hyprland use the 'wm-exec-hypr' wrapper.\n' >&2";
      };

      packages = [
        (pkgs.writeShellApplication {
          name = "wm-exec-hypr";
          text = "Hyprland";
        })
      ];
    };

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;

      extraConfig = builtins.readFile ./hyprland.conf;

      settings = {
        "$mod" = "SUPER";

        inherit (cfg) monitor;

        exec-once = cfg.autoStartApps ++ (lib.optional cfg.waybar.enable "waybar");

        input = {
          kb_layout = cfg.keyboard.layout;
          kb_variant = cfg.keyboard.variant;
        };

        bind = [
          # "$mod ALT, Q, exit"
        ] ++
        (
          let
            numWorkspaces = 9;
          in
          with builtins; concatMap
            (i:
              let
                ws = toString (i);
                workspaceNumber = toString (i);
              in
              [
                "$mod, ${ws}, workspace, ${workspaceNumber}"
                "$mod SHIFT, ${ws}, movetoworkspace, ${workspaceNumber}"
              ]
            )
            (genList (x: x + 1) numWorkspaces)
        );
      };
    };

    programs.waybar = lib.mkIf cfg.waybar.enable {
      enable = true;

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;

          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [ "tray" "clock" ];

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
