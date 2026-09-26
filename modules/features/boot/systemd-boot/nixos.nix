# systemd-boot on EFI. No generation cap: nix.gc prunes old generations.
{
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub.enable = false;
    systemd-boot.enable = true;
  };
}
