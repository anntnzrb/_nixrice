{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.virtualisation.docker;
in
{
  imports = [ inputs.self.nixosModules.user ];

  options.liberion.virtualisation.docker = {
    enableOnBoot = mkOptDisabled';
  };

  config = {
    virtualisation.docker = {
      enable = true;

      inherit (cfg) enableOnBoot;

      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    liberion.user.extraGroups = [ "docker" ];
  };
}
