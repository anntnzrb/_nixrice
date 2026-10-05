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
    }:
    { config, pkgs, ... }:
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
      arguments = [
        (lib.getExe updater)
        repository
        "${config.home.homeDirectory}/${destination}"
        branch
      ];
    in
    {
      systemd.user = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        services.${name} = {
          Unit.Description = "Prepare and fast-forward the ${description} source checkout";
          Service = {
            Type = "oneshot";
            ExecStart = lib.escapeShellArgs arguments;
            TimeoutStartSec = 120;
            Nice = 19;
          };
        };
        timers.${name} = {
          Unit.Description = "Update the ${description} source checkout every five minutes";
          Timer = {
            OnStartupSec = "1min";
            OnUnitInactiveSec = "5min";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };

      launchd.agents.${name} = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        enable = true;
        config = {
          ProgramArguments = arguments;
          RunAtLoad = true;
          StartInterval = 300;
          ProcessType = "Background";
          LowPriorityIO = true;
          Nice = 19;
        };
      };
    };

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
