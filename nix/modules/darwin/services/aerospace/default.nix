{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptDisabled'
    getModuleFiles'
    ;

  cfg = config.${namespace}.services.aerospace;
in
{
  imports = getModuleFiles' ./.;

  options.${namespace}.services.aerospace = {
    enable = mkOptDisabled';

    modifier = mkOpt' lib.types.str "alt";
  };

  config = lib.mkIf cfg.enable {
    services.aerospace = {
      inherit (cfg) enable;
    };

    # goodies
    # cf. https://nikitabobko.github.io/AeroSpace/goodies
    system.defaults.NSGlobalDomain = {
      NSWindowShouldDragOnGesture = true;
      NSAutomaticWindowAnimationsEnabled = true;
    };
  };
}
