{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.virtualisation.virt-manager;
in
{
  options.${namespace}.virtualisation.virt-manager = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      onShutdown = "shutdown";
    };

    programs.virt-manager.enable = true;

    ${namespace}.nixos.user.extraGroups = [ "libvirtd" ];
  };
}
