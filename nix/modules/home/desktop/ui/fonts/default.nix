{
  config,
  pkgs,
  lib,
  ...
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
      bqn386
      font-awesome_6
      (nerdfonts.override {
        fonts = [
          "CodeNewRoman"
          "FantasqueSansMono"
          "FiraCode"
          "Inconsolata"
          "JetBrainsMono"
          "Mononoki"
          "Overpass"
          "UbuntuMono"
          "VictorMono"
          "ZedMono"
        ];
      })
    ];
  };
}
