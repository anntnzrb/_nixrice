{
  lib,
  self,
  inputs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';

  cfg = config.liberion.nix;
  userName = lib.liberion.identity.user;

  # clan machines reached over tailscale magicdns on their openssh port (22 is
  # taken by tailscale ssh, whose host key is not the clan-managed one)
  builderHost = name: "${name}.${config.clan.core.settings.domain}";
  builderPort = lib.liberion.identity.sshPort;
  sshKey = "/Users/${userName}/.ssh/liberion"; # the daemon (root) uses the fleet key
  features = [
    "benchmark"
    "big-parallel"
    "kvm"
    "nixos-test"
  ];

  # one builder as a Nix machines-file line, for `--builders @/etc/nix/builders/<name>`
  machineLine =
    name: maxJobs:
    "ssh-ng://${userName}@${builderHost name}:${toString builderPort} x86_64-linux ${sshKey} ${toString maxJobs} 1 ${lib.concatStringsSep "," features} - -";
in
{
  imports = [ inputs.determinate.darwinModules.default ];

  options.liberion.nix = {
    # x86_64-linux remote builders this Mac trusts: clan machine name -> max
    # jobs. Each gets its host key pinned, ssh set up and a spec file, so any
    # command can pick it: `nix build ... --builders @/etc/nix/builders/<name>`
    # (or `--builders ''` to build locally).
    builders = mkOpt' (lib.types.attrsOf lib.types.ints.positive) { };
    # the builders Nix uses when a command does not pick any
    defaultBuilders = mkOpt' (lib.types.listOf (
      lib.types.enum (lib.attrNames cfg.builders)
    )) [ ];
  };

  config = {
    assertions = [
      {
        assertion = lib.all (name: self.clan.inventory.machines ? ${name}) (
          lib.attrNames cfg.builders
        );
        message = "liberion.nix.builders names a machine that is not in the clan inventory.";
      }
    ];

    # Determinate Nix manages /etc/nix/nix.conf, so disable nix-darwin's nix module to avoid conflicts
    nix.enable = false;

    determinateNix = {
      # Custom settings written to /etc/nix/nix.custom.conf
      customSettings = {
        extra-substituters = lib.attrNames cfg.caches;
        trusted-substituters = lib.attrNames cfg.caches;
        extra-trusted-public-keys = lib.attrValues cfg.caches;
        trusted-users = [
          "root"
          "@admin"
        ];
        builders-use-substitutes = lib.mkIf (cfg.builders != { }) true;
      };

      distributedBuilds = cfg.defaultBuilders != [ ];
      buildMachines = map (name: {
        hostName = "${builderHost name}:${toString builderPort}";
        protocol = "ssh-ng";
        sshUser = userName;
        inherit sshKey;
        systems = [ "x86_64-linux" ];
        maxJobs = cfg.builders.${name};
        supportedFeatures = features;
      }) cfg.defaultBuilders;

      determinateNixd = {
        # Daemon-side background GC; replaces nix-darwin's nix.gc.*
        # (unusable while the nix module is off for Determinate)
        garbageCollector.strategy = "automatic";
        telemetry.sentry.endpoint = null;
      };
    };

    environment.etc = lib.mapAttrs' (
      name: maxJobs:
      lib.nameValuePair "nix/builders/${name}" {
        text = machineLine name maxJobs + "\n";
      }
    ) cfg.builders;

    # nix sets no ssh timeout; fail over quickly when a builder is offline
    programs.ssh.extraConfig = lib.concatMapStrings (name: ''
      Host ${builderHost name}
        ConnectTimeout 5
    '') (builtins.attrNames cfg.builders);

    # pin the clan-generated openssh host keys of the builders
    programs.ssh.knownHosts = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "${name}-builder" {
        hostNames = [ "[${builderHost name}]:${toString builderPort}" ];
        publicKey = lib.trim (
          builtins.readFile (
            self + "/vars/per-machine/${name}/openssh/ssh.id_ed25519.pub/value"
          )
        );
      }
    ) cfg.builders;

    # macOS sudoers keeps HOME by default, letting root-run tools pollute the
    # user's home (~/.cache and friends); drop it so root gets /var/root.
    security.sudo.extraConfig = ''
      Defaults env_keep -= "HOME"
    '';

    system.activationScripts.postActivation.text = ''
      if launchctl print system/systems.determinate.nix-daemon >/dev/null 2>&1; then
        launchctl kickstart -k system/systems.determinate.nix-daemon
      fi
    '';
  };
}
