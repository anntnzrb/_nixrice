{ lib, ... }: {
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub.enable = false;
    systemd-boot = {
      enable = true;
      configurationLimit = lib.mkDefault 10;
    };
  };
}
