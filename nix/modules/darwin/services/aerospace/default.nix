{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.services.aerospace;
in
{
  options.${namespace}.services.aerospace = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.aerospace.enable = true;

    # goodies
    # cf. https://nikitabobko.github.io/AeroSpace/goodies
    system.defaults.NSGlobalDomain = {
      NSWindowShouldDragOnGesture = true;
      NSAutomaticWindowAnimationsEnabled = true;
    };
  };
}
