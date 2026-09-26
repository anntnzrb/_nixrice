{
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = false;

    grub = {
      enable = true;

      configurationLimit = 20;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
  };
}
