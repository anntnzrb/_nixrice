{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.boot.bootloader.grub;
in
{
  options.${namespace}.boot.bootloader.grub = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot.enable = false;

      grub = {
        enable = true;

        configurationLimit = 20;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
      };
    };
  };
}
