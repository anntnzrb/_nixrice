{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.virtualisation.virtualbox;
in
{
  imports = [ inputs.self.nixosModules.user ];

  options.liberion.virtualisation.virtualbox = {
    enableExtensionPack = mkOptDisabled';
  };

  config = {
    virtualisation.virtualbox = {
      host = {
        enable = true;

        inherit (cfg) enableExtensionPack;
      };
    };

    users.users.${lib.liberion.identity.user}.extraGroups = [ "vboxusers" ];
  };
}
