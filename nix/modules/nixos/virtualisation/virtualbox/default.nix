{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.virtualisation.virtualbox;
in
{
  options.${namespace}.virtualisation.virtualbox = {
    enable = mkOptDisabled';
    enableExtensionPack = mkOptDisabled';
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
