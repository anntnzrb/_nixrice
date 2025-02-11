{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  host,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';
  inherit (lib) mkIf types;
  inherit (pkgs.stdenvNoCC.hostPlatform) isLinux;

  cfg = config.${namespace}.network.ssh;
  defaultSSHKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG6ELJkEgYejto4kzTLbNrzGFJWQRBSYUQi0aSoqXUoB sops";

  availableHosts =
    (inputs.self.nixosConfigurations or { })
    // (inputs.self.darwinConfigurations or { });

  otherHostsConfig =
    lib.foldl'
      (
        acc: remoteName:
        let
          remote = availableHosts.${remoteName};
          remoteUser = remote.config.${namespace}.user.name;
        in
        acc
        // {
          ${remoteName} = {
            hostname = "${remoteName}.local";
            user = remoteUser;
            forwardAgent = true;
            port = lib.mkIf (builtins.hasAttr remoteName availableHosts) cfg.port;
          };
        }
      )
      { }
      (
        builtins.attrNames (
          lib.filterAttrs (
            name: entry:
            name != host && (entry.config.${namespace}.user.name or null) != null
          ) availableHosts
        )
      );
in
{
  options.${namespace}.network.ssh = with types; {
    enable = mkOptDisabled';
    authorizedKeys = mkOpt' (listOf str) [ defaultSSHKey ];
    extraConfig = mkOpt' str "";
    port = mkOpt' port 2222;
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      inherit (cfg) enable;
      addKeysToAgent = "yes";
      matchBlocks = otherHostsConfig;
      extraConfig = ''
        StreamLocalBindUnlink yes
        ${cfg.extraConfig}
      '';
    };

    home.file.".ssh/authorized_keys".text =
      builtins.concatStringsSep "\n" cfg.authorizedKeys;

    services.ssh-agent = mkIf isLinux {
      inherit (cfg) enable;
    };
  };
}
