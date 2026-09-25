# Global DHCP (dhcpcd on every interface). Exclusive with network.networkmanager,
# whose upstream module pins networking.useDHCP = false.
_: { networking.useDHCP = true; }
