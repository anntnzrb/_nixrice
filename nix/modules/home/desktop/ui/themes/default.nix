{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.liberion.desktop.ui.themes;
in
{
  options.liberion.desktop.ui.themes = with lib; {
    enable = mkEnableOption "themes";

    cursor = {
      theme = mkOption {
        type = types.str;
        default = "macOS-BigSur";
      };

      size = mkOption {
        type = types.ints.u8;
        default = 28;
      };
    };

    iconTheme = mkOption {
      type = types.str;
      default = "Papirus-Dark";
    };

    theme = mkOption {
      type = types.str;
      default = "Dracula";
    };
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
