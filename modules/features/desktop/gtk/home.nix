{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) str ints;

  cfg = config.liberion.desktop.gtk;
in
{
  options.liberion.desktop.gtk = {
    cursor = {
      theme = mkOpt' str "macOS-BigSur";
      size = mkOpt' ints.u8 28;
    };

    iconTheme = mkOpt' str "Papirus-Dark";
    theme = mkOpt' str "Dracula";
  };

  config = {
    gtk = {
      enable = true;
      gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      gtk4.theme = config.gtk.theme;

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
