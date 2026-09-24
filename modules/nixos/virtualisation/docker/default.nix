{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.virtualisation.docker;
in
{
  options.${namespace}.virtualisation.docker = {
    enable = mkOptDisabled';
    enableOnBoot = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      inherit (cfg) enable;

      inherit (cfg) enableOnBoot;

      autoPrune = on // {
        dates = "weekly";
      };
    };

    ${namespace}.user.extraGroups = [ "docker" ];
  };
}
