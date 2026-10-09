{ inputs, lib, ... }: {
  imports = [
    (lib.liberion.darwin.homebrewApps [ "tinycast" ])
    inputs.self.darwinModules.launcher-hotkey
  ];

  config = {
    liberion.darwin.launcher-hotkey.owners = [ "tinycast" ];

    system.defaults.CustomUserPreferences."com.tinycast.app" = {
      "hotkey.togglePalette" = builtins.toJSON {
        combo._0 = {
          carbonKeyCode = 49;
          carbonModifiers = 256;
        };
      };
      fileSearchEnabled = true;
    };

    launchd.user.agents.tinycast = lib.liberion.darwin.openAtLogin "Tinycast" "modules/features/programs/tinycast";
  };
}
