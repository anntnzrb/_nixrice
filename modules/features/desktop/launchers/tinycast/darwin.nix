{ lib, ... }: {
  imports = [
    (lib.liberion.darwin.homebrewApps [ "tinycast" ])
    (lib.liberion.darwin.gatekeeperApproval [ "/Applications/Tinycast.app" ])
    ./launcher-hotkey.nix
  ];

  liberion.darwin.owned.privacy = [
    {
      service = "Accessibility";
      bundleId = "com.abueammar.tinycast";
    }
    {
      service = "SystemPolicyAllFiles";
      bundleId = "com.abueammar.tinycast";
    }
  ];

  system.defaults.CustomUserPreferences."com.abueammar.tinycast" = {
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
