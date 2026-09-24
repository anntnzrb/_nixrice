{
  lib,
  config,
  inputs,
  host,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';

  cfg = config.${namespace}.network.ssh;

  nixosCfg = inputs.self.nixosConfigurations or { };
  darwinCfg = inputs.self.darwinConfigurations or { };

  remoteHosts = lib.filterAttrs (
    hostName: hostCfg:
    hostName != host && (hostCfg.config.${namespace}.user.name or null) != null
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
        Hostname ${remoteHostName}.local
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
  };

  config = lib.mkIf cfg.enable {
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
