{ config
, lib
, ...
}:
let
  cfg = config.liberion.common.xorg.picom;
in
{
  options.liberion.common.xorg.picom = with lib.liberion; with lib.types; {
    enable = mkOptBool';
    backend = mkOpt' str "glx";
  };

  config = lib.mkIf cfg.enable {
    services.picom = {
      enable = true;

      inherit (cfg) backend;

      vSync = false;

      # opacity
      activeOpacity = 1.0;
      inactiveOpacity = 1.0;
      menuOpacity = 1.0;

      # animations
      fade = true;
      fadeDelta = 5;

      # shadows
      shadow = true;
      shadowOpacity = 0.8;
    };
  };
}
