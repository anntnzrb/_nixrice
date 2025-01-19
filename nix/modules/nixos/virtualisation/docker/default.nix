{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.virtualisation.docker;
in
{
  options.${namespace}.virtualisation.docker = with lib.${namespace}; {
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

    ${namespace}.nixos.user.extraGroups = [ "docker" ];
  };
}
