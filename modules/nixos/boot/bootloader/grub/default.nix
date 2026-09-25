{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled' off;

  cfg = config.liberion.boot.bootloader.grub;
in
{
  options.liberion.boot.bootloader.grub = {
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
