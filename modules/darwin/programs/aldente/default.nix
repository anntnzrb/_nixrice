# AlDente setup beyond its cask (programs/default.nix owns the toggle).
{ lib, config, ... }: {
  config = lib.mkIf config.liberion.programs.aldente.enable {
    system.defaults.CustomUserPreferences."com.apphousekitchen.aldente-pro" = {
      launchAtLogin = false;
    };

    # Opens the app via /usr/bin/open; launchd supervises open, not the GUI
    # process.
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
      managedBy = "liberion.programs.aldente.enable";
    };
  };
}
