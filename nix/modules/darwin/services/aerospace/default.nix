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
  imports = [
    ./workspaces.nix
    ./rules.nix
    ./nodes.nix
  ];

  options.${namespace}.services.aerospace = with lib.${namespace}; {
    enable = mkOptBool';

    modifier = lib.mkOption {
      type = lib.types.str;
      default = "alt";
      description = "Primary modifier key for bindings";
    };
  };

  config = lib.mkIf cfg.enable {
    services.aerospace.enable = true;

    services.aerospace.settings = {
      # colored borders for active windows
      # cf. https://nikitabobko.github.io/AeroSpace/goodies#highlight-focused-windows-with-colored-borders
      after-startup-command = [
        "exec-and-forget borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0"
      ];
    };

    # goodies
    # cf. https://nikitabobko.github.io/AeroSpace/goodies
    system.defaults.NSGlobalDomain = {
      NSWindowShouldDragOnGesture = true;
      NSAutomaticWindowAnimationsEnabled = true;
    };
  };
}
