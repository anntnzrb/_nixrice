{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.virtualisation.virtualbox;
in
{
  options.liberion.virtualisation.virtualbox = {
    enable = mkOptDisabled';
    enableExtensionPack = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.virtualbox = {
      host = {
        inherit (cfg) enable;

        inherit (cfg) enableExtensionPack; # causes recompilation
      };
    };

    liberion.user.extraGroups = [ "vboxusers" ];
  };
}
