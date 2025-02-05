{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.virtualisation.virt-manager;
in
{
  options.${namespace}.virtualisation.virt-manager = {
    enable = mkOptBool';
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
