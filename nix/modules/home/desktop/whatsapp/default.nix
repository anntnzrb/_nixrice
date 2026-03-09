{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptDisabled'
    ;
  inherit (lib.types)
    bool
    enum
    ints
    str
    ;

  cfg = config.${namespace}.desktop.whatsapp;
  idleCfg = cfg.idleQuit;

  enabled = cfg.enable && idleCfg.enable;
  homeDir = config.home.homeDirectory;

  stateDirDefault = "${homeDir}/Library/Application Support/liberion/whatsapp-idle-guard";
  logDirDefault = "${homeDir}/Library/Logs/liberion";

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

    (lib.mkIf enabled {
      assertions = [
        {
          assertion = idleCfg.bundleId != "";
          message = "${namespace}.desktop.whatsapp.idleQuit.bundleId must be set when idle quit is enabled.";
        }
      ];

      home.activation.whatsappIdleGuardDirs =
        config.lib.dag.entryAfter [ "writeBoundary" ]
          ''
            run ${lib.getExe ensureDirs} \
              ${lib.escapeShellArg idleCfg.stateDir} \
              ${lib.escapeShellArg idleCfg.logDir}
          '';

      launchd.agents.whatsapp-idle-guard = {
        enable = true;
        config = {
          ProgramArguments = [ (lib.getExe idleGuard) ] ++ idleGuardArgs;
          RunAtLoad = true;
          StartInterval = idleCfg.pollSeconds;
          ProcessType = "Background";
          LimitLoadToSessionType = [ "Aqua" ];
          StandardOutPath = outLogFile;
          StandardErrorPath = errLogFile;
        };
      };
    })
  ];
}
