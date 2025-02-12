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
    ;

  cfg = config.${namespace}.services.aerospace;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.services.aerospace = {
    enable = mkOptDisabled';

    modifier = mkOpt' lib.types.str "alt";
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
