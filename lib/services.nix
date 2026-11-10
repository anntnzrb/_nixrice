{ lib, root }:
let
  # A user service starts with a bare PATH; this one reaches the sync-managed
  # wrappers, Home Manager and system profiles, and the base system tools.
  userPath =
    config:
    let
      home = config.home.homeDirectory;
    in
    lib.concatStringsSep ":" [
      "${home}/.local/bin"
      "${home}/.bun/bin"
      "${home}/.nix-profile/bin"
      "/etc/profiles/per-user/${config.home.username}/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];

  # The agents sync CLI from its installed runtime, never from the checkout.
  agentsSync = config: [
    "${config.home.homeDirectory}/.local/share/agents/sync-current/sync"
  ];

  nightlyHours = [
    3
    4
    5
  ];

  # A module's Python script as an executable on the nixpkgs interpreter. Its
  # tests run repo-wide in the flake's `checks.python`.
  pythonScript =
    pkgs:
    {
      libraries ? _: [ ],
      name,
      script,
    }:
    pkgs.runCommand name { meta.mainProgram = name; } ''
      mkdir -p $out/bin
      {
        echo '#!${(pkgs.python3.withPackages libraries).interpreter}'
        sed '1{/^#!/d}' ${script}
      } > $out/bin/${name}
      chmod +x $out/bin/${name}
    '';

  # launchd opens StandardOutPath eagerly, so its directory must exist first.
  launchdLog =
    name:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      dir = "${config.home.homeDirectory}/Library/Logs";
    in
    {
      config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        home.activation.launchdLogs =
          lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
            ''
              run mkdir -p ${lib.escapeShellArg dir}
            '';
        launchd.agents.${name}.config = {
          StandardOutPath = "${dir}/${name}.log";
          StandardErrorPath = "${dir}/${name}.log";
        };
      };
    };

  # A scheduled oneshot user job at idle priority: a systemd service and timer
  # on Linux, a launchd agent on Darwin. `schedule` is "nightly" or an interval
  # in seconds; `startup` (seconds) also runs it shortly after login or boot.
  userJob =
    {
      command,
      description,
      name,
      schedule,
      startup ? null,
      timeout ? null,
    }:
    { config, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

      nightly = schedule == "nightly";
      # launchd runs a stable path, so each run picks up the current generation
      # and launchd has no timeout of its own.
      launcher = ".local/libexec/${name}";
      timeoutCommand = lib.optionalString (
        timeout != null
      ) "${lib.getExe' pkgs.coreutils "timeout"} ${toString timeout} ";
      launcherCommand = "exec ${timeoutCommand}${lib.escapeShellArgs command}";
    in
    {
      imports = [ (launchdLog name) ];

      assertions = [
        {
          assertion = nightly || builtins.isInt schedule;
          message = "userJob ${name}: schedule must be \"nightly\" or seconds";
        }
      ];

      home.file.${launcher} = lib.mkIf isDarwin {
        source = pkgs.writeShellScript name launcherCommand;
      };

      systemd.user = lib.mkIf isLinux {
        services.${name} = {
          Unit.Description = description;
          Service = {
            Type = "oneshot";
            ExecStart = lib.escapeShellArgs command;
            Environment = [ "PATH=${userPath config}" ];
            Nice = 19;
            IOSchedulingClass = "idle";
          }
          // lib.optionalAttrs (timeout != null) { TimeoutStartSec = timeout; };
        };
        timers.${name} = {
          Unit.Description = description;
          Timer =
            if nightly then
              {
                OnCalendar = "*-*-* ${toString (lib.head nightlyHours)}..${toString (lib.last nightlyHours)}:00:00";
                RandomizedDelaySec = "20min";
                Persistent = true;
              }
            else
              {
                OnUnitInactiveSec = schedule;
              }
              // lib.optionalAttrs (startup != null) { OnStartupSec = startup; };
          Install.WantedBy = [ "timers.target" ];
        };
      };

      launchd.agents.${name} = lib.mkIf isDarwin {
        enable = true;
        config = {
          ProgramArguments = [ "${config.home.homeDirectory}/${launcher}" ];
          EnvironmentVariables.PATH = userPath config;
          ProcessType = "Background";
          LowPriorityIO = true;
          Nice = 19;
        }
        // (
          if nightly then
            {
              StartCalendarInterval = map (hour: {
                Hour = hour;
                Minute = 0;
              }) nightlyHours;
            }
          else
            {
              StartInterval = schedule;
              RunAtLoad = startup != null;
            }
        );
      };
    };

  # A long-running user service on Linux and/or Darwin. Autostart and
  # keepalive are independent; launchd also accepts a PathState policy.
  userService =
    {
      autostart ? true,
      command,
      darwinOnly ? false,
      description,
      environment ? { },
      keepalive ? true,
      launchdExitTimeout ? null,
      launchdProcessType ? null,
      name,
    }:
    { config, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

      home = config.home.homeDirectory;
      env = environment // {
        PATH = userPath config;
      };
    in
    {
      imports = [ (launchdLog name) ];

      systemd.user = lib.mkIf (isLinux && !darwinOnly) {
        services.${name} = {
          Unit = {
            Description = description;
            After = [ "network-online.target" ];
          };
          Service = {
            ExecStart = lib.escapeShellArgs command;
            Environment = lib.mapAttrsToList (key: value: "${key}=${value}") env;
            WorkingDirectory = home;
            Restart = if keepalive then "always" else "no";
            RestartSec = 5;
          };
          Install.WantedBy = if autostart then [ "default.target" ] else lib.mkForce [ ];
        };
      };

      launchd.agents.${name} = lib.mkIf isDarwin {
        enable = true;
        config = {
          ProgramArguments = command;
          EnvironmentVariables = env;
          WorkingDirectory = home;
          RunAtLoad = autostart;
          KeepAlive = keepalive;
          ThrottleInterval = 5;
        }
        // lib.optionalAttrs (launchdProcessType != null) {
          ProcessType = launchdProcessType;
        }
        // lib.optionalAttrs (launchdExitTimeout != null) {
          ExitTimeOut = launchdExitTimeout;
        };
      };
    };

  # Nightly job that restarts a wrapper-launched `userService` onto the
  # wrapper's newest release once `kind` (see modules/features/ai/
  # idle-restart.py) reports no work in flight.
  idleRestartJob =
    {
      extraArgs ? [ ],
      kind,
      schedule ? "nightly",
      service,
      startup ? null,
      wrapper,
    }:
    { pkgs, ... }@args:
    let
      idleRestart = lib.getExe (
        pythonScript pkgs {
          name = "idle-restart";
          script = root + "/modules/features/ai/idle-restart.py";
        }
      );
      serviceName =
        if pkgs.stdenv.hostPlatform.isLinux then
          "${service}.service"
        else
          "org.nix-community.home.${service}";
    in
    userJob {
      name = "${service}-update";
      description = "Restart ${service} onto its newest release when idle";
      inherit schedule startup;
      timeout = 900;
      command = [
        idleRestart
        "--kind"
        kind
        "--wrapper"
        wrapper
        "--service"
        serviceName
      ]
      ++ extraArgs;
    } args;

  zshInit =
    pkgs: name: command:
    pkgs.runCommand "${name}-zsh-init" { } ''
      HOME=$TMPDIR ${command} > $out
    '';

  gitCheckout =
    {
      branch,
      description,
      destination,
      name,
      repository,
      update ? null,
    }:
    { config, pkgs, ... }@args:
    let
      updater = pkgs.writeShellApplication {
        name = "update-${name}";
        runtimeInputs = with pkgs; [
          coreutils
          git
          openssh
        ];
        text = builtins.readFile ./git-checkout.sh;
      };
    in
    userJob {
      inherit name;
      description = "Prepare and fast-forward the ${description} source checkout";
      command = [
        (lib.getExe updater)
        repository
        "${config.home.homeDirectory}/${destination}"
        branch
      ]
      ++ lib.optional (update != null) (
        lib.getExe (update {
          inherit config pkgs;
        })
      );
      schedule = 300;
      startup = 60;
      timeout = 1200;
    } args;
in
{
  inherit
    userPath
    agentsSync
    pythonScript
    userJob
    userService
    idleRestartJob
    zshInit
    gitCheckout
    ;
}
