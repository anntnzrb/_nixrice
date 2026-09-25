import ../../../../toggle.nix "boot.bootloader.systemd-boot" (
  { lib, ... }:
  let
    inherit (lib.liberion.module) off;
  in
  {
    boot.loader = {
      grub = off;

      systemd-boot = {
        enable = true;

        configurationLimit = 20;
        consoleMode = "auto";
      };
    };
  }
)
