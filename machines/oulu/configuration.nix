{ lib, pkgs, ... }:
let
  inherit (lib.liberion.module) on off;
in
{
  nixpkgs.hostPlatform = "x86_64-linux";

  clan.core.enableRecommendedDefaults = true;

  liberion = {
    profiles = {
      server = on;
      headless = on;
    };
    virtualisation.podman = on;
    # oulu predates these liberion baselines; it owns its boot and packages
    boot = off // {
      bootloader = off;
    };
    environment = off;
  };

  system.stateVersion = "26.05";

  # NetworkManager defaults already rank ethernet (enp3s0, metric 100) over
  # wifi (wlp2s0, metric 600)
  networking.networkmanager = on;

  environment = {
    localBinInPath = true;
    systemPackages = [ pkgs.ripgrep ];
  };
  programs.nix-ld = on;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot = on;
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

  services.tailscale = on // {
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
  programs.fish = on;

  home-manager = {
    useUserPackages = true;
    users.annt.imports = [ ./home.nix ];
  };
}
