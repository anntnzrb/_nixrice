{ pkgs
, config
, ...
}: {
  gtk = {
    enable = true;
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

    cursorTheme = {
      package = pkgs.apple-cursor;
      name = "macOS-BigSur";
      size = 28;
    };

    theme = {
      name = "Catppuccin-Mocha-Compact-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        size = "compact";
        accents = [ "blue" ];
        variant = "mocha";
      };
    };
  };
}
