{ lib, ... }: {
  imports = [ (lib.liberion.darwin.homebrewApps [ "aldente" ]) ];

  config = {
    system.defaults.CustomUserPreferences."com.apphousekitchen.aldente-pro" = {
      launchAtLogin = false;
    };

    launchd.user.agents.aldente = lib.liberion.darwin.openAtLogin "AlDente" "modules/features/programs/aldente";
  };
}
