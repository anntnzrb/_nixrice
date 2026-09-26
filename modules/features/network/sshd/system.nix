{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';

  cfg = config.liberion.network.ssh;
  userName = lib.liberion.identity.user;

  inherit (lib.liberion.identity) keys;

  # every other live fleet machine, as annt@<name>.<tailnet domain> (archived
  # machines are left out); the clan inventory knows each class, so no peer
  # config is evaluated
  remoteHostsCfg = lib.concatStringsSep "\n" (
    lib.mapAttrsToList
      (name: machine: ''
        Host ${name}
          Hostname ${name}.${config.clan.core.settings.domain}
          User ${userName}
          ForwardAgent yes
          ${lib.optionalString (
            machine.machineClass == "nixos"
          ) "Port ${toString cfg.port}\n"}
      '')
      (
        lib.filterAttrs (_: machine: !(builtins.elem "archived" machine.tags)) (
          removeAttrs inputs.self.clan.inventory.machines [
            config.clan.core.settings.machine.name
          ]
        )
      )
  );
in
{
  options.liberion.network.ssh = with lib.types; {
    extraConfig = mkOpt' str "";
    port = mkOpt' port lib.liberion.identity.sshPort;
    authorizedKeys = mkOpt' (listOf singleLineStr) ([ keys.admin ] ++ keys.devices);
  };

  config = {
    users.users.${userName}.openssh.authorizedKeys.keys = cfg.authorizedKeys;

    programs.ssh = {
      extraConfig = ''
        ${remoteHostsCfg}

        ${cfg.extraConfig}
      '';

      knownHosts = {
        git = {
          hostNames = [ "git" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+2YoDrSYPW7ucDqCz/lpNvFzLo4ZY3I1Afg/SV5N3P git";
        };
      };
    };
  };
}
