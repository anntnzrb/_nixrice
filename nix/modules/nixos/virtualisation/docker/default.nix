{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.virtualisation.docker;
in
{
  options.${namespace}.virtualisation.docker = {
    enable = mkOptBool';
    enableOnBoot = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;

      inherit (cfg) enableOnBoot;

      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    ${namespace}.user.extraGroups = [ "docker" ];
  };
}
