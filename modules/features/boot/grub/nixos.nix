{
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
}
