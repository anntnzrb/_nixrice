{ lib, root }:
let
  identity = import (root + "/identity.nix");

  mkOpt' =
    type: default:
    lib.mkOption {
      inherit type default;
      description = null;
    };

  classes = [
    "nixos"
    "darwin"
    "home"
    "system"
  ];

  discover =
    root:
    let
      isClassFile =
        path:
        let
          rel = lib.removePrefix (toString root) (toString path);
        in
        !(lib.hasInfix "/_" rel)
        && builtins.elem (baseNameOf rel) (map (c: "${c}.nix") classes);
      byDir = lib.groupBy (path: toString (dirOf path)) (
        builtins.filter isClassFile (lib.filesystem.listFilesRecursive root)
      );
      named = lib.mapAttrs' (
        dir: paths:
        lib.nameValuePair (baseNameOf dir) (
          lib.listToAttrs (
            map (p: lib.nameValuePair (lib.removeSuffix ".nix" (baseNameOf p)) p) paths
          )
        )
      ) byDir;
    in
    assert lib.assertMsg (
      lib.length (lib.attrNames named) == lib.length (lib.attrNames byDir)
    ) "two module directories below ${toString root} share a name";
    named;

  load =
    roots:
    let
      base = discover roots.base;
      features = discover roots.features;
      profiles = discover roots.profiles;

      forClass =
        class: route:
        lib.concatMapAttrs (
          name: files:
          let
            own =
              lib.optional (class != "home" && files ? system) files.system
              ++ lib.optional (files ? ${class}) files.${class};
          in
          lib.optionalAttrs (own != [ ]) {
            ${name} =
              if class == "home" then
                files.home
              else
                {
                  key = "liberion/${class}/${name}";
                  imports =
                    own
                    ++ lib.optional (route && files ? home) {
                      home-manager.users.${identity.user}.imports = [ files.home ];
                    };
                };
          }
        );

      modules = lib.genAttrs [ "nixos" "darwin" "home" ] (
        class:
        assert lib.assertMsg (
          lib.intersectLists (lib.attrNames features) (lib.attrNames profiles) == [ ]
        ) "a feature and a profile share a name";
        forClass class true (features // profiles)
        // {
          default.imports = lib.attrValues (forClass class false base);
        }
      );
    in
    {
      inherit modules;

      machineModule = class: tags: home: {
        imports = [
          modules.${class}.default
        ]
        ++ lib.optional (builtins.pathExists home) {
          home-manager.users.${identity.user}.imports = [
            modules.home.default
            home
          ];
        }
        ++ map (tag: modules.${class}.${tag}) (
          builtins.filter (tag: profiles ? ${tag} && modules.${class} ? ${tag}) tags
        );
      };
    };

  fleet = load {
    base = root + "/modules/base";
    features = root + "/modules/features";
    profiles = root + "/modules/profiles";
  };

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
    "${config.home.homeDirectory}/.local/share/agents/sync-current/.venv/bin/python"
    "-m"
    "sync.cli"
  ];

  nightlyHours = [
    3
    4
    5
  ];

  # A scheduled oneshot user job at idle priority: a systemd service and timer
  # on Linux, a launchd agent on Darwin. `schedule` is "nightly" or an interval
  # in seconds; `startup` (seconds) also runs it shortly after login or boot.
  userJob =
    {
      name,
      description,
      command,
      schedule,
      startup ? null,
      timeout ? null,
    }:
    { config, pkgs, ... }:
    let
      nightly = schedule == "nightly";
      log = "${config.home.homeDirectory}/Library/Logs/${name}.log";
    in
    assert lib.assertMsg (
      nightly || builtins.isInt schedule
    ) "userJob ${name}: schedule must be \"nightly\" or seconds";
    {
      systemd.user = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
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

      launchd.agents.${name} = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        enable = true;
        config = {
          ProgramArguments = command;
          EnvironmentVariables.PATH = userPath config;
          ProcessType = "Background";
          LowPriorityIO = true;
          Nice = 19;
          StandardOutPath = log;
          StandardErrorPath = log;
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

  # A long-running user service restarted whenever it exits: a systemd user
  # service on Linux, a kept-alive launchd agent on Darwin.
  userService =
    {
      name,
      description,
      command,
      environment ? { },
    }:
    { config, pkgs, ... }:
    let
      home = config.home.homeDirectory;
      env = environment // {
        PATH = userPath config;
      };
      log = "${home}/Library/Logs/${name}.log";
    in
    {
      systemd.user = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        services.${name} = {
          Unit = {
            Description = description;
            After = [ "network-online.target" ];
          };
          Service = {
            ExecStart = lib.escapeShellArgs command;
            Environment = lib.mapAttrsToList (key: value: "${key}=${value}") env;
            WorkingDirectory = home;
            Restart = "always";
            RestartSec = 5;
          };
          Install.WantedBy = [ "default.target" ];
        };
      };

      launchd.agents.${name} = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        enable = true;
        config = {
          ProgramArguments = command;
          EnvironmentVariables = env;
          WorkingDirectory = home;
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 5;
          StandardOutPath = log;
          StandardErrorPath = log;
        };
      };
    };

  # Nightly job that restarts a wrapper-launched `userService` onto the
  # wrapper's newest release once `kind` (see modules/features/ai/
  # idle-restart.py) reports no work in flight.
  idleRestartJob =
    {
      service,
      kind,
      wrapper,
      extraArgs ? [ ],
    }:
    { pkgs, ... }@args:
    userJob {
      name = "${service}-update";
      description = "Restart ${service} onto its newest release when idle";
      schedule = "nightly";
      timeout = 900;
      command = [
        (lib.getExe pkgs.python3)
        "${root + "/modules/features/ai/idle-restart.py"}"
        "--kind"
        kind
        "--wrapper"
        wrapper
        "--service"
        (
          if pkgs.stdenv.hostPlatform.isLinux then
            "${service}.service"
          else
            "org.nix-community.home.${service}"
        )
      ]
      ++ extraArgs;
    } args;

  zshInit =
    pkgs: name: command:
    pkgs.runCommand "${name}-zsh-init" { } ''
      ${command} > $out
    '';

  gitCheckout =
    {
      name,
      description,
      repository,
      destination,
      branch,
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
  inherit identity load;
  inherit (fleet) modules machineModule;

  authorizedKeys = [ identity.keys.admin ] ++ identity.keys.devices;

  isArchived = machine: builtins.elem "archived" machine.tags;

  module = {
    inherit mkOpt';
    mkOptEnabled' = mkOpt' lib.types.bool true;
    mkOptDisabled' = mkOpt' lib.types.bool false;
  };

  inherit
    userPath
    agentsSync
    userJob
    userService
    idleRestartJob
    zshInit
    gitCheckout
    ;

  darwin = rec {
    wmHandoff = { pkgs, user }: import ./wm-handoff.nix { inherit lib pkgs user; };

    asUser =
      user:
      ''launchctl asuser "$(id -u -- ${lib.escapeShellArg user})" sudo --user=${lib.escapeShellArg user} --'';

    activateSettings = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u";

    writeDefault =
      {
        domain,
        key,
        value,
        currentHost ? false,
      }:
      lib.concatStringsSep " " (
        [ "defaults" ]
        ++ lib.optional currentHost "-currentHost"
        ++ [
          "write"
          (lib.escapeShellArg domain)
          (lib.escapeShellArg key)
          (lib.escapeShellArg (lib.generators.toPlist { escape = true; } value))
        ]
      );

    writeDefaults =
      user:
      {
        domain,
        settings,
        currentHost ? false,
      }:
      lib.mapAttrsToList (
        key: value:
        "${asUser user} ${
          writeDefault {
            inherit
              domain
              key
              value
              currentHost
              ;
          }
        }"
      ) (lib.filterAttrs (_: v: v != null) settings);

    aquaAgent =
      managedBy: agent:
      lib.recursiveUpdate {
        inherit managedBy;
        serviceConfig = {
          RunAtLoad = true;
          ProcessType = "Interactive";
          LimitLoadToSessionType = [ "Aqua" ];
        };
      } agent;

    openAtLogin =
      app: managedBy:
      aquaAgent managedBy {
        serviceConfig = {
          ProgramArguments = [
            "/usr/bin/open"
            "-a"
            "/Applications/${app}.app"
          ];
          KeepAlive = false;
        };
      };
  };

  xorg.mkAutostartScript = xs: lib.concatStringsSep "\n" (map (x: x + " &") xs);
}
