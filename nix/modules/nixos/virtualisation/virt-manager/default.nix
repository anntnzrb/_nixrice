{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.virtualisation.virt-manager;
in
{
  options.${namespace}.virtualisation.virt-manager = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      onShutdown = "shutdown";
    };

    programs.virt-manager.enable = true;

    ${namespace}.user.extraGroups = [ "libvirtd" ];
  };
}
