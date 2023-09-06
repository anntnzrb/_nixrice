{pkgs, ...}: {
  boot = {
    initrd.availableKernelModules = ["xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
    kernelModules = ["kvm-intel"];
    kernelPackages = pkgs.linuxPackages_zen;
  };
}
