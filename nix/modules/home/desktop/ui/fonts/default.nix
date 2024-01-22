{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.desktop.ui.fonts;
in
{
  options.liberion.desktop.ui.fonts = {
    enable = lib.mkEnableOption "fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      apl386
      dejavu_fonts
      nerdfonts
      mononoki

      iosevka-comfy.comfy
      iosevka-comfy.comfy-duo
      iosevka-comfy.comfy-motion
      iosevka-comfy.comfy-motion-duo
    ];
  };
}
