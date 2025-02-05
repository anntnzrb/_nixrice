{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace})
    mkOpt'
    mkOptBool'
    ;

  cfg = config.${namespace}.common.xorg.picom;
in
{
  options.${namespace}.common.xorg.picom = {
    enable = mkOptBool';
    backend = mkOpt' lib.types.str "glx";
    vSync = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.picom = {
      enable = true;

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
