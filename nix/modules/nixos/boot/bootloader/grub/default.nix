{ config, lib, ... }:
let
  cfg = config.liberion.boot.bootloader.grub;
in
{
  options.liberion.boot.bootloader.grub = with lib.liberion; {
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
