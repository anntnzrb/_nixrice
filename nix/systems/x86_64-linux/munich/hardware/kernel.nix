{ pkgs
, ...
}: rec {
  boot = {
    initrd.availableKernelModules = [ "vmd" "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
  };

  # support for tablets
  hardware.opentabletdriver.enable = true;
}
