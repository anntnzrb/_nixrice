{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.self.clan.inventory) machines;
  inherit (config.clan.core) settings;

  cfg = config.liberion.network.sshd;
  userName = lib.liberion.identity.user;
  remoteHostsCfg = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: machine: ''
      Host ${name}
        Hostname ${name}.${settings.domain}
        User ${userName}
        ForwardAgent yes
        ${lib.optionalString (
          machine.machineClass == "nixos"
        ) "Port ${toString cfg.port}\n"}
    '') (lib.liberion.fleetPeers machines settings.machine.name)
  );
in
{
  programs.ssh = {
    extraConfig = ''
      ${remoteHostsCfg}

      ${cfg.extraConfig}
    '';

    knownHosts.git = {
      hostNames = [ "git" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+2YoDrSYPW7ucDqCz/lpNvFzLo4ZY3I1Afg/SV5N3P git";
    };
  };
}
