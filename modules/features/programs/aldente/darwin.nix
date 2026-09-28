{ inputs, ... }: {
  imports = [ inputs.self.darwinModules.homebrew ];

  config = {
    liberion.homebrew.apps = [ "aldente" ];

    system.defaults.CustomUserPreferences."com.apphousekitchen.aldente-pro" = {
      launchAtLogin = false;
    };

    launchd.user.agents.aldente = {
      serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "/Applications/AlDente.app"
        ];
        RunAtLoad = true;
        KeepAlive = false;
        ProcessType = "Interactive";
        LimitLoadToSessionType = [ "Aqua" ];
      };
      managedBy = "modules/features/programs/aldente";
    };
  };
}
