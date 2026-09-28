{ lib, inputs, ... }: {
  imports = [ inputs.self.darwinModules.homebrew ];

  config = {
    liberion.homebrew.apps = [ "aldente" ];

    system.defaults.CustomUserPreferences."com.apphousekitchen.aldente-pro" = {
      launchAtLogin = false;
    };

    launchd.user.agents.aldente = lib.liberion.darwin.openAtLogin "AlDente" "modules/features/programs/aldente";
  };
}
