# `server-laptop` profile

Apply this tag alongside `server` and `headless` to a NixOS laptop used as a
headless server. The existing tags supply server power behavior and disable the
GUI; this profile adds NetworkManager and Tailscale, disables networkd and
Facter's detected DHCP service, and prefers Ethernet (route metric 100) over
Wi-Fi (600) for both IPv4 and IPv6. The defaults match device type, so they
cover every Ethernet and Wi-Fi interface without naming devices.
Connection profiles with explicitly configured metrics override these defaults.

Clan's tag-targeted `wifi` instance provisions the shared `home` network to
machines tagged `server-laptop`, using Clan vars for its credentials. Adding the
tag opts a machine into that Wi-Fi configuration.

This covers link loss, not an upstream outage while Ethernet still has carrier.
The metrics only choose a route while a link is available. If both Ethernet
and Wi-Fi are down, remote access is unavailable until a link returns. After a
full power loss, automatic recovery requires firmware that powers the laptop on
when AC returns; otherwise recovery needs physical access.
