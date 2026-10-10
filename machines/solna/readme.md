# Solna

HP 15-dw0083wm repurposed as a headless server for light services and backups.
It is not a fleet Nix builder.

## Hardware

| Component | Specification |
| --- | --- |
| CPU | Intel Pentium Silver N5000, four cores/four threads |
| Graphics | Intel UHD Graphics 605 |
| RAM | 8 GB |
| Storage | Lite-On CV8-8E128-HP, 128 GB SATA M.2 SSD |
| Ethernet | Realtek RTL8111 family, `r8169` |
| Wi-Fi | Realtek RTL8821CE, `rtw88_8821ce` |
| Boot | UEFI with systemd-boot |

Hardware detection is managed by `facter.json`. Disko replaces all partitions
on the internal SSD with a 1 GiB FAT32 ESP and an unencrypted ext4 root.
The disk is selected by its stable ID in `disk.nix`.

## Operation

Amp's runner and its restart timer are disabled on this host. T3 and the
CLIProxyAPI gateway remain enabled.

Ethernet is the primary connection; Clan provisions Wi-Fi as a fallback.
The `server-laptop` tag selects the shared NetworkManager-only profile and
home Wi-Fi credentials. Its target declares Ethernet metric 100 and Wi-Fi
metric 600 for IPv4 and IPv6 by device type. Both links may stay connected;
this handles link loss, not an upstream outage with carrier still present.
The server profile disables sleep and lid-triggered suspension, enables ZRAM,
and configures key-only SSH. Tailscale enrollment is separate from enabling
its daemon. Automatic power-on after battery exhaustion is not verified.

The read-only audit on 2026-10-09 observed both interfaces connected with
Ethernet/Wi-Fi route metrics 100/600 before the shared-profile change.
Physical closed-lid and cable-loss
recovery tests remain pending.

`home.nix` receives the shared Home Manager base through machine discovery.
GitHub CLI and direnv settings belong to their shared feature modules; system
and hardware configuration remain machine-specific.
