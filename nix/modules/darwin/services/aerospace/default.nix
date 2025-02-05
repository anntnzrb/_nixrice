{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.services.aerospace;
in
{
  imports = [
    ./workspaces.nix
    ./rules.nix
    ./nodes.nix
  ];

  options.${namespace}.services.aerospace = {
    enable = mkOptBool';

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
