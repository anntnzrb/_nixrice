{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.fonts;
in {
  options.liberion.desktop.fonts = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      apl386
      fantasque-sans-mono
      fira-code
      fira-code-symbols
      font-awesome
      iosevka
      mononoki
      nerdfonts
    ];
  };
}
