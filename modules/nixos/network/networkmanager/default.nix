import ../../../toggle.nix "network.networkmanager" (
  { pkgs, ... }: {
    networking.networkmanager.enable = true;
    environment.systemPackages = [ pkgs.networkmanagerapplet ];
  }
)
