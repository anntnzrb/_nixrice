{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) ints str;

  cfg = config.liberion.desktop.whatsapp;
  dir = lib.types.pathWith {
    absolute = true;
    inStore = false;
  };

  homeDir = config.home.homeDirectory;

  idleGuard = pkgs.writeShellApplication {
    name = "whatsapp-idle-guard";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
    ];
    text = builtins.readFile ./whatsapp-idle-guard.sh;
  };

  ensureDirs = pkgs.writeShellApplication {
    name = "ensure-whatsapp-idle-guard-dirs";
    runtimeInputs = with pkgs; [ coreutils ];
    text = builtins.readFile ./ensure-whatsapp-idle-guard-dirs.sh;
  };
in
{
  options.liberion.desktop.whatsapp = {
    bundleId = mkOpt' str "net.whatsapp.WhatsApp";
    timeoutMinutes = mkOpt' ints.positive 60;
    sleepBlockMinutes = mkOpt' ints.positive 10;
    pollSeconds = mkOpt' ints.positive 60;
    killGraceSeconds = mkOpt' ints.positive 10;
    stateDir = mkOpt' dir "${homeDir}/Library/Application Support/rice/whatsapp-idle-guard";
    logDir = mkOpt' dir "${homeDir}/Library/Logs/rice";
  };

  config = {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "liberion.desktop.whatsapp is only supported on Darwin.";
      }
    ];

    home.activation.whatsappIdleGuardDirs =
      config.lib.dag.entryAfter [ "writeBoundary" ]
        ''
          run ${lib.getExe ensureDirs} \
            ${lib.escapeShellArg cfg.stateDir} \
            ${lib.escapeShellArg cfg.logDir}
        '';

    launchd.agents.whatsapp-idle-guard = {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe idleGuard)
          cfg.bundleId
          cfg.stateDir
          (toString (cfg.timeoutMinutes * 60))
          (toString (cfg.sleepBlockMinutes * 60))
          (toString cfg.killGraceSeconds)
        ];
        RunAtLoad = true;
        StartInterval = cfg.pollSeconds;
        ProcessType = "Background";
        LimitLoadToSessionType = [ "Aqua" ];
        StandardOutPath = "${cfg.logDir}/whatsapp-idle-guard.log";
        StandardErrorPath = "${cfg.logDir}/whatsapp-idle-guard.error.log";
      };
    };
  };
}
