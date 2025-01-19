{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.ui.fonts;
in
{
  options.${namespace}.desktop.ui.fonts = with lib.${namespace}; {
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
