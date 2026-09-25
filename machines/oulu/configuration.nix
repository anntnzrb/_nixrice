{ pkgs, inputs, ... }: {
  imports = [ inputs.self.nixosModules.podman ];

  # oulu predates these liberion baselines; it owns its boot and packages
  disabledModules = [
    ../../modules/base/boot/nixos.nix
    ../../modules/base/environment/system.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  clan.core.enableRecommendedDefaults = true;

  system.stateVersion = "26.05";

  # NetworkManager defaults already rank ethernet (enp3s0, metric 100) over
  # wifi (wlp2s0, metric 600)
  networking.networkmanager.enable = true;

  environment = {
    localBinInPath = true;
    systemPackages = [ pkgs.ripgrep ];
  };
  programs.nix-ld.enable = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "ahci"
      "r8169"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "kvm-intel"
      # realtek 8852be wifi on the lenovo v15 g4
      "rtw89_8852be"
    ];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--ssh"
      "--hostname=oulu"
      "--accept-routes=true"
    ];
  };

  users.users.annt = {
    extraGroups = [ "networkmanager" ];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  home-manager.useUserPackages = true;
}
