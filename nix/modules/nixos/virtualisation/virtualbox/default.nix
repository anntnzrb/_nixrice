{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.virtualisation.virtualbox;
in
{
  options.${namespace}.virtualisation.virtualbox = {
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

    ${namespace}.user.extraGroups = [ "vboxusers" ];
  };
}
