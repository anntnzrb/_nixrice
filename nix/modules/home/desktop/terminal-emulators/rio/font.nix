{
  lib,
  pkgs,
  ...
}:
let
  fonts = {
    iosevka-comfy-motion = {
      name = "Iosevka Comfy Motion";
      pkg = pkgs.iosevka-comfy.comfy-motion;
    };
    zedmono-nerd = {
      name = "ZedMono Nerd Font";
      pkg = pkgs.nerdfonts.override {
        fonts = [ "ZedMono" ];
      };
    };
  };
in
{
  config = {
    home.packages = lib.attrsets.mapAttrsToList (_: font: font.pkg) fonts;

    programs.rio.settings.fonts = {
      size = 14;

      regular = {
        family = fonts.iosevka-comfy-motion.name;
        style = "Normal";
        weight = 400;
      };

      bold = {
        family = fonts.iosevka-comfy-motion.name;
        style = "Normal";
        weight = 800;
      };

      italic = {
        family = fonts.iosevka-comfy-motion.name;
        style = "Italic";
        weight = 400;
      };

      bold-italic = {
        family = fonts.iosevka-comfy-motion.name;
        style = "Italic";
        weight = 800;
      };
    };
  };
}
