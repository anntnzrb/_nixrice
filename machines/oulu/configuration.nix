{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    disko-xfs
    fish
    intel-cpu
    kernel-latest
    # NetworkManager defaults already rank ethernet (enp3s0, metric 100) over
    # wifi (wlp2s0, metric 600)
    networkmanager
    podman
    systemd-boot
    tailscale
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.05";

  environment.localBinInPath = true;
  programs.nix-ld.enable = true;

  # agents run in the owner's ssh session: let oomd kill the heaviest one under
  # memory pressure instead of zram thrashing until the kernel oom killer fires
  systemd.oomd.enableUserSlices = true;

  # hardware facts of the lenovo v15 g4
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
    # realtek 8852be wifi
    kernelModules = [ "rtw89_8852be" ];
  };
}
