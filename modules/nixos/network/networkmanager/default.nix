import ../../../toggle.nix "network.networkmanager" (
  { pkgs, ... }: {
    networking.useDHCP = false;

    networking.networkmanager.enable = true;
    environment.systemPackages = [ pkgs.networkmanagerapplet ];
  }
)
