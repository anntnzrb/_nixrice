{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types)
    bool
    enum
    ints
    str
    ;
  # an absolute path outside the store
  dir = lib.types.pathWith {
    absolute = true;
    inStore = false;
  };

  cfg = config.liberion.desktop.whatsapp;
  idleCfg = cfg.idleQuit;
  sleepCfg = cfg.sleepQuit;

  idleEnabled = idleCfg.enable;
  sleepEnabled = sleepCfg.enable;
  anyEnabled = idleEnabled || sleepEnabled;
  homeDir = config.home.homeDirectory;
  sleepwatcherSource = "${pkgs.sleepwatcher}/bin/sleepwatcher";
  sleepwatcherPath = "${homeDir}/Library/Application Support/rice/bin/sleepwatcher";

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

  sleepwatcherArgs =
    lib.optionals sleepCfg.onSystemSleep [
      "-s"
      sleepQuitCommand
    ]
    ++ lib.optionals sleepCfg.onDisplaySleep [
      "-S"
      sleepQuitCommand
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
  options.liberion.desktop.whatsapp = {
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

      stateDir = mkOpt' dir stateDirDefault;
      logDir = mkOpt' dir logDirDefault;

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
    {
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isDarwin;
          message = "liberion.desktop.whatsapp is only supported on Darwin.";
        }
      ];
    }

    (lib.mkIf anyEnabled {
      assertions = [
        {
          assertion = idleCfg.bundleId != "";
          message = "liberion.desktop.whatsapp.idleQuit.bundleId must be set when the WhatsApp guard is enabled.";
        }
        {
          assertion =
            (!sleepEnabled) || sleepCfg.onDisplaySleep || sleepCfg.onSystemSleep;
          message = "liberion.desktop.whatsapp.sleepQuit must enable at least one trigger.";
        }
        {
          assertion = (!sleepEnabled) || (sleepCfg.killGraceSeconds < 15);
          message = "liberion.desktop.whatsapp.sleepQuit.killGraceSeconds must stay below 15 seconds for sleepwatcher hooks.";
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

    (lib.mkIf idleEnabled {
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

    (lib.mkIf sleepEnabled {
      launchd.agents.whatsapp-sleepwatcher = {
        enable = true;
        config = {
          ProgramArguments = [ sleepwatcherPath ] ++ sleepwatcherArgs;
          KeepAlive = true;
          RunAtLoad = true;
          ProcessType = "Background";
          LimitLoadToSessionType = [ "Aqua" ];
          StandardOutPath = "${idleCfg.logDir}/whatsapp-sleepwatcher.log";
          StandardErrorPath = "${idleCfg.logDir}/whatsapp-sleepwatcher.error.log";
        };
      };

      # Stage the sleepwatcher binary to a stable path via temp file + rename,
      # so launchd always executes the same absolute path.
      home.activation."whatsapp-sleepwatcher-stable-executable" =
        config.lib.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
          ''
            stable_path=${lib.escapeShellArg sleepwatcherPath}
            stable_dir="$(dirname "$stable_path")"
            tmp_path="$stable_path.tmp.$$"
            trap 'rm -f "$tmp_path"' EXIT

            run mkdir -p "$stable_dir"
            run cp ${lib.escapeShellArg sleepwatcherSource} "$tmp_path"
            run chmod 0755 "$tmp_path"
            run mv -f "$tmp_path" "$stable_path"
          '';
    })
  ];
}
