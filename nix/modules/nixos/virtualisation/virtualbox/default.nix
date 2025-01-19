{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.virtualisation.virtualbox;
in
{
  options.${namespace}.virtualisation.virtualbox = with lib.${namespace}; {
    enable = mkOptBool';
    enableExtensionPack = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.virtualbox = {
      host = {
        enable = true;

        inherit (cfg) enableExtensionPack; # causes recompilation
      };
    };

    ${namespace}.nixos.user.extraGroups = [ "vboxusers" ];
  };
}
