{ lib, config, ... }:
let
  cfg = config.liberion.virtualisation.docker;
in
{
  options.liberion.virtualisation.docker = with lib.liberion; {
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

    liberion.nixos.user.extraGroups = [ "docker" ];
  };
}
