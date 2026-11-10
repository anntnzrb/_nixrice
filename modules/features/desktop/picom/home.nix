{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';

  cfg = config.liberion.desktop.picom;
in
{
  options.liberion.desktop.picom = {
    backend = mkOpt' lib.types.str "glx";
    vSync = mkOptDisabled';
  };

  config.services.picom = {
    enable = true;
    inherit (cfg) backend vSync;

    activeOpacity = 1.0;
    inactiveOpacity = 1.0;
    menuOpacity = 1.0;
    fade = true;
    fadeDelta = 5;
    shadow = true;
    shadowOpacity = 0.8;
  };
}
