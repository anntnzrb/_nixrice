{ inputs, lib, ... }: {
  imports = with inputs.self.nixosModules; [
    ./disk.nix
    fish
    networkmanager
    systemd-boot
    tailscale
  ];

  home-manager.users.${lib.liberion.identity.user}.imports = [ ./_home.nix ];

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
