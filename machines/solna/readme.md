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

Ethernet is the primary connection; Clan provisions Wi-Fi as a fallback.
The server profile disables sleep and lid-triggered suspension, enables ZRAM,
and configures key-only SSH. Tailscale enrollment is separate from enabling
its daemon. Automatic power-on after battery exhaustion is not verified.

`_home.nix` explicitly selects administration tools and Python/JavaScript
runtimes rather than importing the full common Home Manager package set.
