{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled' on;
  inherit (lib.types) attrsOf str;
  inherit (lib)
    mkMerge
    listToAttrs
    map
    elemAt
    length
    range
    ;

  cfg = config.${namespace}.desktop.window-managers.xorg.herbstluftwm;
in
{
  options.${namespace}.desktop.window-managers.xorg.herbstluftwm = {
    enable = mkOptDisabled';

    compositor.picom.enable = mkOptDisabled';

    autoStart = mkOpt' (attrsOf str) [ ];
    keys.super = mkOpt' str "Mod4";
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.common.xorg = on // {
      inherit (cfg.compositor) picom;
    };

    xsession.windowManager.herbstluftwm = rec {
      inherit (cfg) enable;

      tags = map toString (range 1 9);

      settings = {
        always_show_frame = true;
        default_frame_layout = "max";
        frame_bg_active_color = "#000000";
        frame_gap = 12;
        frame_padding = -12;
      };

      keybinds = mkMerge [
        {
          "${cfg.keys.super}-j" = "focus down";
          "${cfg.keys.super}-k" = "focus up";
          "${cfg.keys.super}-h" = "focus left";
          "${cfg.keys.super}-l" = "focus right";
          "${cfg.keys.super}-Shift-q" = "close";
        }
        (listToAttrs (
          map (
            i:
            let
              tag = elemAt tags (i - 1);
            in
            {
              name = "${cfg.keys.super}-${toString i}";
              value = "use ${tag}";
            }
          ) (range 1 (length tags))
        ))
        (listToAttrs (
          map (
            i:
            let
              tag = elemAt tags (i - 1);
            in
            {
              name = "${cfg.keys.super}-Shift-${toString i}";
              value = "move ${tag}";
            }
          ) (range 1 (length tags))
        ))
      ];

      mousebinds = {
        "${cfg.keys.super}-B1" = "move";
        "${cfg.keys.super}-B3" = "resize";
      };

      rules = [
        "focus=on"
        "windowtype~'_NET_WM_WINDOW_TYPE_(DIALOG|UTILITY|SPLASH)' focus=on pseudotile=on"
        "class~'[Pp]inentry' instance=pinentry focus=on floating=on floatplacement=center keys_inactive='.*'"
      ];
    };

    home = {
      shellAliases = {
        wm-exec-herbstluftwm = "command startx ~/${config.xsession.scriptPath}";
      };

      activation = {
        reloadHerbstluftwm = config.lib.dag.entryAfter [
          "writeBoundary"
        ] "${pkgs.herbstluftwm}/bin/herbstluftwm reload || :";
      };
    };
  };
}
