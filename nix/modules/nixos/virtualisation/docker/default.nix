{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.virtualisation.docker;
in
{
  options.${namespace}.virtualisation.docker = {
    enable = mkOptDisabled';
    enableOnBoot = mkOptDisabled';
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
