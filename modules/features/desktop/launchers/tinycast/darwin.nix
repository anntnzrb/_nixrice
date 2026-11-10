{ lib, ... }: {
  imports = [
    (lib.liberion.darwin.homebrewApps [ "tinycast" ])
    ./launcher-hotkey.nix
  ];

  liberion.darwin.owned.privacy = [
    {
      service = "Accessibility";
      bundleId = "com.tinycast.app";
    }
  ];

  system.defaults.CustomUserPreferences."com.tinycast.app" = {
    "hotkey.togglePalette" = builtins.toJSON {
      combo._0 = {
        carbonKeyCode = 49;
        carbonModifiers = 256;
      };
    };
    fileSearchEnabled = true;
  };

  launchd.user.agents.tinycast = lib.liberion.darwin.openAtLogin "Tinycast" "modules/features/desktop/launchers/tinycast";
}
