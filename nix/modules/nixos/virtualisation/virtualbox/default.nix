{ lib
, config
, ...
}:
let
  cfg = config.liberion.virtualisation.virtualbox;
in
{
  options.liberion.virtualisation.virtualbox = {
    enable = lib.mkEnableOption "virtualbox";
    enableExtensionPack = lib.mkEnableOption "virtualbox extension pack?";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.virtualbox = {
      host = {
        enable = true;

        inherit (cfg) enableExtensionPack; # cause recompilation
      };
    };

    liberion.nixos.user.extraGroups = [ "vboxusers" ];
  };
}
