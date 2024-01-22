{ lib
, config
, ...
}:
let
  cfg = config.liberion.virtualisation.virt-manager;
in
{
  options.liberion.virtualisation.virt-manager = {
    enable = lib.mkEnableOption "virt-manager";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      onShutdown = "shutdown";
    };

    programs.virt-manager.enable = true;

    liberion.nixos.user.extraGroups = [ "libvirtd" ];
  };
}
