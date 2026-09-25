import ../../../toggle.nix "network.dhcp" (_: {
  networking.useDHCP = true;
})
