{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';

  cfg = config.liberion.network.ssh;
  userName = config.liberion.user.name;

  inherit (lib.liberion.identity) keys;

  # every other fleet machine, as annt@<name>.<tailnet domain>; the clan
  # inventory knows each class, so no peer config is evaluated
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
        removeAttrs inputs.self.clan.inventory.machines [
          config.clan.core.settings.machine.name
        ]
      )
  );
in
{
  options.liberion.network.ssh = with lib.types; {
    enable = mkOptDisabled';
    extraConfig = mkOpt' str "";
    port = mkOpt' port 2222;
    authorizedKeys = mkOpt' (listOf singleLineStr) ([ keys.admin ] ++ keys.devices);
  };

  config = lib.mkIf cfg.enable {
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
