{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' off;

  cfg = config.${namespace}.boot.bootloader.grub;
in
{
  options.${namespace}.boot.bootloader.grub = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot = off;

      grub = {
        inherit (cfg) enable;

        configurationLimit = 20;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
      };
    };
  };
}
