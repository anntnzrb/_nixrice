{ ... }: {
  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
  };
}
