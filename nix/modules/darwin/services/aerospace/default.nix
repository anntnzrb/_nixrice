{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.aerospace;
in
{
  options.${namespace}.services.aerospace = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      internal = true;
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [
      "${namespace}.services.aerospace is a legacy compatibility shim. Prefer ${namespace}.desktop.window-managers.darwin.aerospace."
    ];

    services.aerospace.enable = true;

    # goodies
    # cf. https://nikitabobko.github.io/AeroSpace/goodies
    system.defaults.NSGlobalDomain = {
      NSWindowShouldDragOnGesture = true;
      NSAutomaticWindowAnimationsEnabled = true;
    };
  };
}
