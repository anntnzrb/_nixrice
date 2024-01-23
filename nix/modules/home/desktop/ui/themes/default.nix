{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.liberion.desktop.ui.themes;
in
{
  options.liberion.desktop.ui.themes = with lib.liberion; with lib.types; {
    enable = mkOptBool';

    cursor = {
      theme = mkOpt' str "macOS-BigSur";
      size = mkOpt' ints.u8 28;
    };

    iconTheme = mkOpt' str "Papirus-Dark";
    theme = mkOpt' str "dracula";
  };

  config = with lib; mkIf cfg.enable {
    gtk = {
      enable = true;
      gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

      cursorTheme = mkIf (cfg.cursor.theme == "macOS-BigSur") {
        name = cfg.cursor.theme;
        package = pkgs.apple-cursor;
        size = cfg.cursor.size;
      };

      iconTheme = mkIf (cfg.iconTheme == "Papirus-Dark") {
        name = cfg.iconTheme;
        package = pkgs.papirus-icon-theme;
      };

      theme = mkIf (cfg.theme == "Dracula") {
        name = cfg.theme;
        package = pkgs.dracula-theme;
      };
    };
  };
}
