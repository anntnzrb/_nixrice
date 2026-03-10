{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    ;
  inherit (lib.${namespace}.launchd.darwin) mkGuiAppAgent;

  cfg = config.${namespace}.programs.raycast;

  raycastHotkey = "Command-49"; # ⌘ Space
in
{
  options.${namespace}.programs.raycast = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable (
    {
      ${namespace}.homebrew.packages.casks = [ "raycast" ];

      system.defaults.CustomUserPreferences."com.raycast.macos" = {
        mainWindow_isMonitoringGlobalHotkeys = true;
        raycastGlobalHotkey = raycastHotkey;
      };
    }
    // mkGuiAppAgent {
      name = "raycast";
      app = "/Applications/Raycast.app";
      managedBy = "${namespace}.programs.raycast.enable";
    }
  );
}
