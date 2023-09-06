{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) types mkIf;
  inherit (lib.liberion) mkOpt' mkOptBool';

  cfg = config.liberion.desktop.picom;
in {
  options.liberion.desktop.picom = with types; {
    enable = mkOptBool' false;
    backend = mkOpt' str "glx";
    vSync = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    services.picom = {
      enable = true;

      inherit (cfg) backend vSync;

      # opacity
      activeOpacity = 1.0;
      inactiveOpacity = 1.0;
      menuOpacity = 1.0;

      fade = true;
      fadeDelta = 6;
      shadow = true;
      shadowOpacity = 0.8;
    };
  };
}
