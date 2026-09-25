# Global DHCP (dhcpcd on every interface). Exclusive with network.networkmanager,
# whose upstream module pins networking.useDHCP = false.
import ../../../toggle.nix "network.dhcp" (_: {
  networking.useDHCP = true;
})
