{
  lib,
  config,
  namespace,
  host,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptEnabled';
  inherit (lib)
    mkIf
    mkOption
    optional
    concatLists
    optionalAttrs
    mkMerge
    flatten
    mapAttrs
    mapAttrsToList
    ;

  inherit (lib.types)
    attrsOf
    submodule
    anything
    nullOr
    str
    ;

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
      } // optionalAttrs (user != null) { inherit user; };

      files = concatLists [
        (optional (keys.public != null) (mkKeyFile "${name}.pub" keys.public))
        (optional (keys.private != null) (mkKeyFile name keys.private))
      ];
    };

in
{
  options.${namespace}.ssh = {
    enable = mkOptEnabled';
    hosts = mkOption {
      type = attrsOf (
        submodule (
          { name, ... }:
          {
            freeformType = attrsOf anything;
            options = {
              hostname = mkOption {
                type = str;
                default = name;
                description = "SSH server hostname";
              };
              keys = mkOption {
                type = submodule {
                  options = {
                    public = mkOption {
                      type = nullOr str;
                      default = null;
                      description = "Public key content";
                    };
                    private = mkOption {
                      type = nullOr str;
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

  config = mkIf cfg.enable {
    programs.ssh = {
      inherit (cfg) enable;
      hashKnownHosts = true;
      matchBlocks = mapAttrs (name: hostCfg: (mkHostConfig name hostCfg).matchBlock) cfg.hosts;
    };

    home.file = mkMerge (
      flatten (mapAttrsToList (name: hostCfg: (mkHostConfig name hostCfg).files) cfg.hosts)
    );
  };
}
