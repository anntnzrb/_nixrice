{
  lib,
  self,
  inputs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' off;

  cfg = config.liberion.nix;
  userName = config.liberion.user.name;

  # clan machines reached over tailscale magicdns on their openssh port (22 is
  # taken by tailscale ssh, whose host key is not the clan-managed one)
  builderHost = name: "${name}.${config.clan.core.settings.domain}";
  builderPort = config.liberion.network.ssh.port;
in
{
  imports = [ inputs.determinate.darwinModules.default ];

  options.liberion.nix.builders =
    mkOpt' (lib.types.attrsOf lib.types.ints.positive) { }
    // {
      description = "x86_64-linux remote builders: clan machine name -> max jobs.";
    };

  config = lib.mkIf cfg.enable {
    # Determinate Nix manages /etc/nix/nix.conf, so disable nix-darwin's nix module to avoid conflicts
    nix = off;

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

      distributedBuilds = cfg.builders != { };
      buildMachines = lib.mapAttrsToList (name: maxJobs: {
        hostName = "${builderHost name}:${toString builderPort}";
        protocol = "ssh-ng";
        sshUser = userName;
        # root (the daemon) authenticates with the fleet key
        sshKey = "/Users/${userName}/.ssh/liberion";
        systems = [ "x86_64-linux" ];
        inherit maxJobs;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }) cfg.builders;

      determinateNixd = {
        # Daemon-side background GC; replaces nix-darwin's nix.gc.*
        # (unusable while the nix module is off for Determinate)
        garbageCollector.strategy = "automatic";
        telemetry.sentry.endpoint = null;
      };
    };

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
