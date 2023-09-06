{pkgs, ...}: {
  boot = {
    initrd.availableKernelModules = ["vmd" "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod"];
    kernelModules = ["kvm-intel"];
    kernelPackages = pkgs.linuxPackages_zen;
  };
}
