{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    networkmanager
    tailscale
  ];

  hardware.facter.detected.dhcp.enable = false;

  networking = {
    networkmanager.settings = {
      connection-ethernet = {
        match-device = "type:ethernet";
        "ipv4.route-metric" = 100;
        "ipv6.route-metric" = 100;
      };
      connection-wifi = {
        match-device = "type:wifi";
        "ipv4.route-metric" = 600;
        "ipv6.route-metric" = 600;
      };
    };
    useNetworkd = false;
  };

  systemd.network.enable = false;
}
