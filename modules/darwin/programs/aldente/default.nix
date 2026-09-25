{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.programs.aldente;
in
{
  options.liberion.programs.aldente = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    liberion.homebrew.packages.casks = [ "aldente" ];

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
