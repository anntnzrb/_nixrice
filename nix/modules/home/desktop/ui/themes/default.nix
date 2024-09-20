{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.liberion.desktop.ui.themes;
in
{
  options.liberion.desktop.ui.themes =
    with lib.liberion;
    with lib.types;
    {
      enable = mkOptBool';

      cursor = {
        theme = mkOpt' str "macOS-BigSur";
        size = mkOpt' ints.u8 28;
      };

      iconTheme = mkOpt' str "Papirus-Dark";
      theme = mkOpt' str "Dracula";
    };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
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
