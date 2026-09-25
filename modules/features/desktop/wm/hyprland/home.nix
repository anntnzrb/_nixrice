{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types) listOf str;

  cfg = config.liberion.desktop.window-managers.wayland.hyprland;
in
{
  imports = [ inputs.self.homeModules.session ];

  options.liberion.desktop.window-managers.wayland.hyprland = {
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

      extraConfig = lib.readFile ./hyprland.conf;

      settings = {
        "$mod" = "SUPER";
        # launched by $mod+Return in hyprland.conf
        "$TERMINAL" = lib.getExe config.liberion.desktop.session.apps.terminal;

        inherit (cfg) monitor;

        exec-once = cfg.autoStartApps ++ (lib.optional cfg.waybar.enable "waybar");

        bind = lib.concatMap (ws: [
          "$mod, ${ws}, workspace, ${ws}"
          "$mod SHIFT, ${ws}, movetoworkspace, ${ws}"
        ]) (map toString (lib.range 1 9));
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
