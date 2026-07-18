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
      inherit (cfg) enable;
      onShutdown = "shutdown";
    };

    programs.virt-manager = { inherit (cfg) enable; };

    ${namespace}.user.extraGroups = [ "libvirtd" ];
  };
}
