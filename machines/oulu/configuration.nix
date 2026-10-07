{ inputs, pkgs, ... }: {
  imports = with inputs.self.nixosModules; [
    amp-runner
    bash
    disko-xfs
    essentials
    kernel-latest
    networkmanager
    podman
    systemd-boot
    t3
    tailscale
  ];

  system.stateVersion = "26.05";

  environment.localBinInPath = true;
  programs.nix-ld.enable = true;

  environment.systemPackages = [ (pkgs.callPackage ./waymote.nix { }) ];

  nix.settings = {
    max-jobs = 6;
    cores = 4;
  };

  systemd.oomd.enableUserSlices = true;

  hardware.facter.detected = {
    bluetooth.enable = false;
    dhcp.enable = false;
  };
}
