{ inputs, lib, ... }: {
  imports = with inputs.self.nixosModules; [
    ./disk.nix
    amp-runner
    bash
    cliproxyapi
    essentials
    networkmanager
    systemd-boot
    t3
    tailscale
  ];

  users.users.${lib.liberion.identity.user}.linger = true;

  home-manager.users.${lib.liberion.identity.user}.liberion.ai = {
    amp-runner.desktop = false;
    t3.settings.backgroundActivity.overrides = {
      providerHealthRefreshInterval = 15 * 60 * 1000;
      automaticGitFetchInterval = 0;
    };
  };

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
