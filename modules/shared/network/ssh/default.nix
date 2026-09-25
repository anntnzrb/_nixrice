{
  lib,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';

  cfg = config.${namespace}.network.ssh;
  userName = config.${namespace}.user.name;

  # one key per device, plus the fleet-wide admin key
  fleetKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB45J5N5vAcQlF4kUHN8y12FMOzXhuav7bczaztcZHTq annt@liberion"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBEpmEC2zcNWEgNAdHDzFZnK7dfOeDVh+r0sasP5PclS annt@beirut"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHzBDSIjkAYW57NffyZkkKeFoA2YGqEKR7mzL5pgYYxV anntnzrb@munich"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJi5TwdwALl2Sw0/MuE+r0u4s35Xw8TftkUQZE2lW3Gr annt@oulu"
  ];

  nixosCfg = inputs.self.nixosConfigurations or { };
  darwinCfg = inputs.self.darwinConfigurations or { };

  remoteHosts = lib.filterAttrs (
    hostName: hostCfg:
    hostName != config.clan.core.settings.machine.name
    && (hostCfg.config.${namespace}.user.name or null) != null
  ) (nixosCfg // darwinCfg);

  remoteHostsCfg = lib.concatMapStringsSep "\n" (
    remoteHostName:
    let
      remote = remoteHosts.${remoteHostName};
      remoteUserName = remote.config.${namespace}.user.name;
      portEntry = lib.optionalString (builtins.hasAttr remoteHostName nixosCfg) ''
        Port ${builtins.toString cfg.port}
      '';
    in
    ''
      Host ${remoteHostName}
        Hostname ${remoteHostName}.${config.clan.core.settings.domain}
        User ${remoteUserName}
        ForwardAgent yes
        ${portEntry}
    ''
  ) (builtins.attrNames remoteHosts);
in
{
  options.${namespace}.network.ssh = with lib.types; {
    enable = mkOptDisabled';
    extraConfig = mkOpt' str "";
    port = mkOpt' port 2222;
    authorizedKeys = mkOpt' (listOf singleLineStr) fleetKeys;
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
