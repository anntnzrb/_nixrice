{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.virtualisation.docker;
in
{
  options.liberion.virtualisation.docker = {
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

    liberion.user.extraGroups = [ "docker" ];
  };
}
