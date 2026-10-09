{ lib, ... }: {
  _class = "clan.service";
  manifest.name = "remote-builders";
  manifest.description = "x86_64-linux remote Nix builders for the fleet's Macs";

  roles.builder = {
    description = "Accepts remote builds from the owner over ssh-ng";
    interface.options.maxJobs = lib.mkOption {
      type = lib.types.ints.positive;
      description = "Jobs a client may run on this builder at once.";
    };
    perInstance.nixosModule = { lib, ... }: {
      nix.settings.trusted-users = [ lib.liberion.identity.user ];
    };
  };

  roles.client = {
    description = "A nix-darwin machine that offloads x86_64-linux builds";
    interface.options.defaultBuilders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Builders Nix uses when a command does not pick any.";
    };
    perInstance = { roles, settings, ... }: {
      darwinModule =
        { config, lib, ... }:
        let
          inherit (config.clan.core.vars) generators;
          builders = lib.mapAttrs (_: m: m.settings.maxJobs) roles.builder.machines;
          userName = lib.liberion.identity.user;
          host = name: "${name}.${config.clan.core.settings.domain}";
          port = lib.liberion.identity.sshPort;
          sshKey = generators.user-ssh.files.id_ed25519.path;
          features = [
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
          ];
          machineLine =
            name: maxJobs:
            "ssh-ng://${userName}@${host name}:${toString port} x86_64-linux ${sshKey} ${toString maxJobs} 1 ${lib.concatStringsSep "," features} - -";
        in
        {
          assertions = [
            {
              assertion = generators ? user-ssh;
              message = "remote-builders: a client authenticates with its admin user-ssh key; tag it admin.";
            }
            {
              assertion = lib.all (name: builders ? ${name}) settings.defaultBuilders;
              message = "remote-builders: defaultBuilders names a machine without the builder role.";
            }
          ];

          determinateNix = {
            customSettings.builders-use-substitutes = true;
            distributedBuilds = settings.defaultBuilders != [ ];
            buildMachines = map (name: {
              hostName = "${host name}:${toString port}";
              protocol = "ssh-ng";
              sshUser = userName;
              inherit sshKey;
              systems = [ "x86_64-linux" ];
              maxJobs = builders.${name};
              supportedFeatures = features;
            }) settings.defaultBuilders;
          };

          environment.etc = lib.mapAttrs' (
            name: maxJobs:
            lib.nameValuePair "nix/builders/${name}" {
              text = machineLine name maxJobs + "\n";
            }
          ) builders;

          programs.ssh.extraConfig = lib.concatMapStrings (name: ''
            Host ${host name}
              ConnectTimeout 5
          '') (lib.attrNames builders);

          programs.ssh.knownHosts = lib.mapAttrs' (
            name: _:
            lib.nameValuePair "${name}-builder" {
              hostNames = [ "[${host name}]:${toString port}" ];
              publicKey = lib.liberion.varValue "per-machine/${name}/openssh/ssh.id_ed25519.pub";
            }
          ) builders;
        };
    };
  };
}
