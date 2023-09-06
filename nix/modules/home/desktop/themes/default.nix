{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) types mkIf;
  inherit (lib.liberion) mkOpt' mkOptBool';

  cfg = config.liberion.desktop.themes;
in {
  options.liberion.desktop.themes = with types; {
    enable = mkOptBool' false;

    cursor = {
      theme = mkOpt' str "macOS-BigSur";
      size = mkOpt' int 28;
    };
    iconTheme = mkOpt' str "Papirus-Dark";
    theme = mkOpt' str "Dracula";
  };

  config = mkIf cfg.enable {
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
