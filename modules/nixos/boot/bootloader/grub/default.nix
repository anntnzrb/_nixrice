import ../../../../toggle.nix "boot.bootloader.grub" (
  { lib, ... }:
  let
    inherit (lib.liberion.module) off;
  in
  {
    boot.loader = {
      systemd-boot = off;

      grub = {
        enable = true;

        configurationLimit = 20;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
      };
    };
  }
)
