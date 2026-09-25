{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.virtualisation.virt-manager;
in
{
  options.liberion.virtualisation.virt-manager = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      inherit (cfg) enable;
      onShutdown = "shutdown";
    };

    programs.virt-manager = { inherit (cfg) enable; };

    liberion.user.extraGroups = [ "libvirtd" ];
  };
}
