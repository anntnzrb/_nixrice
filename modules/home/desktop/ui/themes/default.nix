{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types) str ints;

  cfg = config.liberion.desktop.ui.themes;
in
{
  options.liberion.desktop.ui.themes = {
    enable = mkOptDisabled';

    cursor = {
      theme = mkOpt' str "macOS-BigSur";
      size = mkOpt' ints.u8 28;
    };

    iconTheme = mkOpt' str "Papirus-Dark";
    theme = mkOpt' str "Dracula";
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      inherit (cfg) enable;
      gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

      cursorTheme = {
        name = cfg.cursor.theme;
        package = pkgs.apple-cursor;
        inherit (cfg.cursor) size;
      };

      iconTheme = {
        name = cfg.iconTheme;
        package = pkgs.papirus-icon-theme;
      };

      theme = {
        name = cfg.theme;
        package = pkgs.dracula-theme;
      };
    };
  };
}
