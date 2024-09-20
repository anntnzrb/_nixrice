{ lib, config, ... }:
let
  cfg = config.liberion.virtualisation.virtualbox;
in
{
  options.liberion.virtualisation.virtualbox = with lib.liberion; {
    enable = mkOptBool';
    enableExtensionPack = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.virtualbox = {
      host = {
        enable = true;

        inherit (cfg) enableExtensionPack; # causes recompilation
      };
    };

    liberion.nixos.user.extraGroups = [ "vboxusers" ];
  };
}
