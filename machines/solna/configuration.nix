{ inputs, lib, ... }: {
  imports = with inputs.self.nixosModules; [
    ./disk.nix
    amp-runner
    bash
    cliproxyapi
    essentials
    networkmanager
    paseo
    systemd-boot
    t3
    tailscale
  ];

  users.users.${lib.liberion.identity.user}.linger = true;

  hardware.facter.detected = {
    bluetooth.enable = false;
    dhcp.enable = false;
  };

  networking.useNetworkd = false;
  systemd.network.enable = false;

  services.fstrim.enable = true;

  nix.settings = {
    max-jobs = 1;
    cores = 2;
  };
}
