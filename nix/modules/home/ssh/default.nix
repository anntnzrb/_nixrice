{
  lib,
  config,
  namespace,
  host,
  ...
}:
let
  cfg = config.${namespace}.ssh;

  sshDir = "${config.home.homeDirectory}/.ssh";

  mkKeyFile = filename: key: {
    "${sshDir}/${filename}" = {
      force = true;
      text = key;
    };
  };

  mkHostConfig =
    name:
    {
      hostname ? host,
      user ? null,
      keys ? { },
      identityFile ? "${sshDir}/${name}",
      identitiesOnly ? true,
    }:
    {
      matchBlock = {
        inherit hostname identityFile identitiesOnly;
      } // lib.optionalAttrs (user != null) { inherit user; };

      files = lib.concatLists [
        (lib.optional (keys.public != null) (mkKeyFile "${name}.pub" keys.public))
        (lib.optional (keys.private != null) (mkKeyFile name keys.private))
      ];
    };

in
{
  options.${namespace}.ssh = with lib; {
    enable = mkEnableOption "SSH configuration";
    hosts = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            freeformType = types.attrsOf types.anything;
            options = {
              hostname = mkOption {
                type = types.str;
                default = name;
                description = "SSH server hostname";
              };
              keys = mkOption {
                type = types.submodule {
                  options = {
                    public = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "Public key content";
                    };
                    private = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "Private key content";
                    };
                  };
                };
                default = { };
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      inherit (cfg) enable;
      hashKnownHosts = true;
      matchBlocks = lib.mapAttrs (name: hostCfg: (mkHostConfig name hostCfg).matchBlock) cfg.hosts;
    };

    home.file = lib.mkMerge (
      lib.flatten (lib.mapAttrsToList (name: hostCfg: (mkHostConfig name hostCfg).files) cfg.hosts)
    );
  };
}
