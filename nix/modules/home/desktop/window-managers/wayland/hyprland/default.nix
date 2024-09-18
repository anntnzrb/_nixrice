{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.wayland.hyprland;
in
{
  options.liberion.desktop.window-managers.wayland.hyprland = with lib.liberion; with lib.types; {
    enable = mkOptBool';

    monitor = mkOpt' (listOf str) [ ",preferred,auto,1" ];
    autoStartApps = mkOpt' (listOf str) [ ];
    waybar = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home = {
      shellAliases = {
        Hyprland = "printf 'Do not use this command. To launch Hyprland use the 'wm-exec-hypr' wrapper.\n' >&2";
        wm-exec-hypr = "\Hyrpland";
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;

      extraConfig = builtins.readFile ./hyprland.conf;

      settings = {
        "$mod" = "SUPER";

        inherit (cfg) monitor;

        exec-once = cfg.autoStartApps ++ (lib.optional cfg.waybar.enable "waybar");

        bind =
          let
            numWorkspaces = 9;
          in
          with builtins; concatMap
            (i:
              let
                ws = toString i;
                workspaceNumber = toString i;
              in
              [
                "$mod, ${ws}, workspace, ${workspaceNumber}"
                "$mod SHIFT, ${ws}, movetoworkspace, ${workspaceNumber}"
              ]
            )
            (genList (x: x + 1) numWorkspaces);
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
