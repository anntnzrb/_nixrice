{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.virtualisation.docker;
in {
  options.liberion.virtualisation.docker = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = false;

      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    liberion.user.extraGroups = ["docker"];
  };
}
