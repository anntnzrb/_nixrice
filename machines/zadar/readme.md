# Zadar

Headless NixOS T3/Amp development server with fleet administrator credentials.
It boots from the HGST HDD with systemd-boot. Peer SSH trust is activated when
peers receive a generation that includes Zadar's admin key.

## Hardware

| Component | Specification |
| --- | --- |
| Laptop | ASUS GL502VMK; UEFI BIOS GL502VMK.308 |
| CPU | Intel Core i7-7700HQ, 4 cores / 8 threads |
| RAM | Approximately 12 GB |
| GPU | NVIDIA GeForce GTX 1060 Mobile, 6 GB; no compute workload configured |
| Disk | HGST HTS721010A9E630, serial `JR1000D30WN62E`, 1,000,204,886,016 bytes |
| Ethernet | Realtek r8169, `enp4s0`, Gigabit Ethernet |
| Wi-Fi | Intel 8260 / iwlwifi, `wlp3s0` |
| Battery | No usable outage reserve; does not charge with AC present |

Hardware detection is managed by `facter.json`.

## Storage and workload

The disk is selected by
`/dev/disk/by-id/ata-HGST_HTS721010A9E630_JR1000D30WN62E`.
The shared XFS layout has a 1 GiB FAT32 EFI partition and the rest is XFS with
`crc=1,reflink=1`. There is no disk encryption or HDD swap; the server profile
supplies zstd zram.

The disk is a 7200 RPM, 512e/4K-sector, SATA 6 Gb/s Travelstar 7K1000 with a
32 MB buffer. The manufacturer's 24/7 Enhanced Availability specification
applies to HTE models, not this HTS model.

Use Zadar for agent sessions and moderate development workloads. Concurrent
dependency installs, checkouts, and builds contend for HDD seeks. XFS reflinks
reduce copying but do not remove that latency. Zadar is not registered as a
remote builder for other hosts.

## Network and power behavior

The `server-laptop` profile supplies NetworkManager management and route
metrics by device type. Ethernet routes have metric 100 and Wi-Fi routes
metric 600 for IPv4 and IPv6. The shared home Wi-Fi profile autoconnects.
This covers loss of the Ethernet link, not an upstream outage while the link
stays up. Both connections depend on the same router.

Fleet SSH uses port 2222 over Ethernet, Wi-Fi, and Tailscale. Avahi supplies
`zadar.local`; Tailscale supplies `zadar`. T3 is available through
`https://zadar.trex-gamut.ts.net:8443/` on the tailnet.

The `server` and `headless` profiles supply power, memory, and graphical-session
policy. Lid actions are ignored and sleep targets are masked. Amp's desktop
mode is disabled. The CPU uses the `powersave` governor.

## Hardware limitations

The battery provides no reserve: abrupt power loss stops the laptop
immediately. XFS journal recovery does not preserve unsynced application data.
Automatic power-on after AC restoration requires a supported BIOS setting or
another hardware recovery mechanism.
