{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';
  inherit (lib.${namespace}.launchd.home) mkAgent;
  inherit (lib.types)
    bool
    enum
    ints
    str
    ;

  cfg = config.${namespace}.desktop.whatsapp;
  idleCfg = cfg.idleQuit;
  sleepCfg = cfg.sleepQuit;

  idleEnabled = cfg.enable && idleCfg.enable;
  sleepEnabled = cfg.enable && sleepCfg.enable;
  anyEnabled = idleEnabled || sleepEnabled;
  homeDir = config.home.homeDirectory;

  stateDirDefault = "${homeDir}/Library/Application Support/rice/whatsapp-idle-guard";
  logDirDefault = "${homeDir}/Library/Logs/rice";

  outLogFile = "${idleCfg.logDir}/whatsapp-idle-guard.log";
  errLogFile = "${idleCfg.logDir}/whatsapp-idle-guard.error.log";

  idleGuardArgs = [
    idleCfg.bundleId
    idleCfg.appName
    idleCfg.mode
    idleCfg.stateDir
    (toString (idleCfg.timeoutMinutes * 60))
    (toString idleCfg.killGraceSeconds)
    (if idleCfg.resetOnFrontmost then "1" else "0")
    (if idleCfg.initializeOnFirstSeen then "1" else "0")
  ];

  sleepQuitArgs = [
    idleCfg.bundleId
    idleCfg.appName
    sleepCfg.mode
    (toString sleepCfg.killGraceSeconds)
  ];

  sleepQuitCommand = lib.escapeShellArgs (
    [ (lib.getExe sleepQuit) ] ++ sleepQuitArgs
  );

  idleGuard = pkgs.writeShellApplication {
    name = "whatsapp-idle-guard";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      gnused
      gawk
    ];
    text = builtins.readFile ./whatsapp-idle-guard.sh;
  };

  sleepQuit = pkgs.writeShellApplication {
    name = "whatsapp-sleep-quit";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      gnused
    ];
    text = builtins.readFile ./whatsapp-sleep-quit.sh;
  };

  ensureDirs = pkgs.writeShellApplication {
    name = "ensure-whatsapp-idle-guard-dirs";
    runtimeInputs = with pkgs; [ coreutils ];
    text = builtins.readFile ./ensure-whatsapp-idle-guard-dirs.sh;
  };
in
{
  options.${namespace}.desktop.whatsapp = {
    enable = mkOptDisabled';

    idleQuit = {
      enable = mkOpt' bool true;

      bundleId = mkOpt' str "net.whatsapp.WhatsApp";
      appName = mkOpt' str "WhatsApp";

      timeoutMinutes = mkOpt' ints.positive 60;
      pollSeconds = mkOpt' ints.positive 60;

      mode = mkOpt' (enum [
        "log-only"
        "term"
        "term-then-kill"
      ]) "term-then-kill";
      killGraceSeconds = mkOpt' ints.positive 10;

      stateDir = mkOpt' str stateDirDefault;
      logDir = mkOpt' str logDirDefault;

      resetOnFrontmost = mkOpt' bool true;
      initializeOnFirstSeen = mkOpt' bool true;
    };

    sleepQuit = {
      enable = mkOpt' bool true;
      mode = mkOpt' (enum [
        "term"
        "term-then-kill"
      ]) "term-then-kill";
      killGraceSeconds = mkOpt' ints.positive 5;
      onDisplaySleep = mkOpt' bool true;
      onSystemSleep = mkOpt' bool true;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isDarwin;
          message = "${namespace}.desktop.whatsapp is only supported on Darwin.";
        }
      ];
    })

    (lib.mkIf anyEnabled {
      assertions = [
        {
          assertion = idleCfg.bundleId != "";
          message = "${namespace}.desktop.whatsapp.idleQuit.bundleId must be set when the WhatsApp guard is enabled.";
        }
        {
          assertion =
            (!sleepEnabled) || sleepCfg.onDisplaySleep || sleepCfg.onSystemSleep;
          message = "${namespace}.desktop.whatsapp.sleepQuit must enable at least one trigger.";
        }
        {
          assertion = (!sleepEnabled) || (sleepCfg.killGraceSeconds < 15);
          message = "${namespace}.desktop.whatsapp.sleepQuit.killGraceSeconds must stay below 15 seconds for sleepwatcher hooks.";
        }
      ];

      home.activation.whatsappIdleGuardDirs =
        config.lib.dag.entryAfter [ "writeBoundary" ]
          ''
            run ${lib.getExe ensureDirs} \
              ${lib.escapeShellArg idleCfg.stateDir} \
              ${lib.escapeShellArg idleCfg.logDir}
          '';
    })

    (lib.mkIf idleEnabled (mkAgent {
      name = "whatsapp-idle-guard";
      serviceConfig = {
        ProgramArguments = [ (lib.getExe idleGuard) ] ++ idleGuardArgs;
        RunAtLoad = true;
        StartInterval = idleCfg.pollSeconds;
        ProcessType = "Background";
        LimitLoadToSessionType = [ "Aqua" ];
        StandardOutPath = outLogFile;
        StandardErrorPath = errLogFile;
      };
    }))

    (lib.mkIf sleepEnabled (mkAgent {
      name = "whatsapp-sleepwatcher";
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.sleepwatcher}/bin/sleepwatcher"
        ]
        ++ lib.optionals sleepCfg.onSystemSleep [
          "-s"
          sleepQuitCommand
        ]
        ++ lib.optionals sleepCfg.onDisplaySleep [
          "-S"
          sleepQuitCommand
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        LimitLoadToSessionType = [ "Aqua" ];
        StandardOutPath = "${idleCfg.logDir}/whatsapp-sleepwatcher.log";
        StandardErrorPath = "${idleCfg.logDir}/whatsapp-sleepwatcher.error.log";
      };
    }))
  ];
}
