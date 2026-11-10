{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) attrsOf enum str;
  inherit (lib)
    mkMerge
    listToAttrs
    elemAt
    length
    range
    ;
  inherit (cfg.keys) super;

  cfg = config.liberion.desktop.wm.herbstluftwm;
  startx = lib.getExe' pkgs.xorg.xinit "startx";
in
{
  imports = [ inputs.self.homeModules.xsession ];

  options.liberion.desktop.wm.herbstluftwm = {
    autoStart = mkOpt' (attrsOf str) { };
    keys.super = mkOpt' (enum [
      "Mod1"
      "Mod4"
    ]) "Mod4";
  };

  config = {
    xsession.windowManager.herbstluftwm =
      let
        tags = map toString (range 1 9);
      in
      {
        enable = true;
        inherit tags;

        settings = {
          always_show_frame = true;
          default_frame_layout = "max";
          frame_bg_active_color = "#000000";
          frame_gap = 12;
          frame_padding = -12;
        };

        keybinds = mkMerge [
          {
            "${super}-j" = "focus down";
            "${super}-k" = "focus up";
            "${super}-h" = "focus left";
            "${super}-l" = "focus right";
            "${super}-Shift-q" = "close";
          }
          (listToAttrs (
            map (
              i:
              let
                tag = elemAt tags (i - 1);
              in
              {
                name = "${super}-${toString i}";
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
                name = "${super}-Shift-${toString i}";
                value = "move ${tag}";
              }
            ) (range 1 (length tags))
          ))
        ];

        mousebinds = {
          "${super}-B1" = "move";
          "${super}-B3" = "resize";
        };

        rules = [
          "focus=on"
          "windowtype~'_NET_WM_WINDOW_TYPE_(DIALOG|UTILITY|SPLASH)' focus=on pseudotile=on"
          "class~'[Pp]inentry' instance=pinentry focus=on floating=on floatplacement=center keys_inactive='.*'"
        ];
      };

    home = {
      shellAliases = {
        wm-exec-herbstluftwm = "${startx} ~/${config.xsession.scriptPath}";
      };

      activation = {
        reloadHerbstluftwm = config.lib.dag.entryAfter [
          "writeBoundary"
        ] "${pkgs.herbstluftwm}/bin/herbstclient reload || :";
      };
    };
  };
}
