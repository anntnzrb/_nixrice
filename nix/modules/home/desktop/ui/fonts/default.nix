{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.desktop.ui.fonts;
in
{
  options.liberion.desktop.ui.fonts = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      apl386
      dejavu_fonts
      font-awesome
      mononoki
      nerdfonts
      noto-fonts-color-emoji

      iosevka-comfy.comfy
      iosevka-comfy.comfy-duo
      iosevka-comfy.comfy-motion
      iosevka-comfy.comfy-motion-duo
    ];
  };
}
