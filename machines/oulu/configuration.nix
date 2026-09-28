{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    disko-xfs
    fish
    intel-cpu
    kernel-latest
    networkmanager
    podman
    systemd-boot
    tailscale
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.05";

  environment.localBinInPath = true;
  programs.nix-ld.enable = true;

  systemd.oomd.enableUserSlices = true;

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "ahci"
      "r8169"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [ "rtw89_8852be" ];
  };
}
