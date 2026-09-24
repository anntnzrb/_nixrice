{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';

  cfg = config.${namespace}.shared.xorg.picom;
in
{
  options.${namespace}.shared.xorg.picom = {
    enable = mkOptDisabled';
    backend = mkOpt' lib.types.str "glx";
    vSync = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.picom = {
      inherit (cfg) enable;

      inherit (cfg) backend vSync;

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
