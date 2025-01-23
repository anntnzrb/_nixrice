{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.ssh;

  sshDir = "${config.home.homeDirectory}/.ssh";

  mkKeyFile =
    { name, key }:
    {
      "${sshDir}/${name}.pub" = {
        force = true;
        text = key;
      };
    };

  mkHostConfig =
    name:
    {
      hostname ? name,
      user ? null,
      keys ? { },
    }:
    {
      matchBlock = {
        inherit hostname;
      } // lib.optionalAttrs (user != null) { inherit user; };

      files = lib.optional (keys ? public) (mkKeyFile {
        inherit name;
        key = keys.public;
      });
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
                      type = types.str;
                      description = "Public key content";
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
      enable = true;
      matchBlocks = lib.mapAttrs (name: hostCfg: (mkHostConfig name hostCfg).matchBlock) cfg.hosts;
    };

    home.file = lib.mkMerge (
      lib.flatten (lib.mapAttrsToList (name: hostCfg: (mkHostConfig name hostCfg).files) cfg.hosts)
    );
  };
}
