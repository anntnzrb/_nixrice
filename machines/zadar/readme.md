# Zadar

## Current state

Installed on 2026-10-09 with the owner's explicit authorization. The hardware
boots the installation's NixOS 26.05 configuration from the HGST HDD with Linux 7.2.8 and
systemd-boot. It is a headless T3/Amp development server with fleet administrator
credentials. Peer SSH trust is activated when each peer receives a generation
that includes Zadar's admin key.

The subsequent `server-laptop` profile refactor moves network management and Ethernet/Wi-Fi
priority into the shared profile, matching interfaces by device type rather
than their individual names. The `server` and `headless` profiles retain the
power, memory, and graphical-session policy.

First-boot SSH was verified as `annt` on port 2222 over both Ethernet
(`192.168.100.101`) and Wi-Fi (`192.168.100.30`). These are DHCP addresses;
`zadar.local` resolves through Avahi. Tailscale enrollment is complete; fleet
SSH was verified through `zadar` on port 2222, with tailnet address
`100.119.41.46` at commissioning.

## Hardware observed on 2026-10-09

| Component | Observed hardware |
| --- | --- |
| Laptop | ASUS GL502VMK; UEFI BIOS GL502VMK.308 |
| CPU | Intel Core i7-7700HQ, 4 cores / 8 threads |
| RAM | Approximately 12 GB |
| GPU | NVIDIA GeForce GTX 1060 Mobile, 6 GB; no compute workload configured |
| Install disk | HGST HTS721010A9E630, serial `JR1000D30WN62E`, 1,000,204,886,016 bytes |
| Ethernet | Realtek r8169, `enp4s0`, negotiated 1 Gb/s full duplex |
| Wi-Fi | Intel 8260 / iwlwifi, `wlp3s0` |
| Battery | 0%, not charging with AC present; no observed outage reserve |

The installation target is exclusively
`/dev/disk/by-id/ata-HGST_HTS721010A9E630_JR1000D30WN62E`.
The 500 GB Hitachi USB disk hosts Ventoy and the live installer. Never format it.
The separate 256 GB SSD moved to Munich is outside this installation.

The target uses the shared XFS layout from Oulu: a 1 GiB EFI partition and the
remaining space for XFS with reflinks. It has no disk encryption or HDD swap;
the server profile supplies zram. Legacy files under `hardware/` are retained
as history and are no longer imported.

## Storage measurements and workload limits

Read-only measurements on the live installer yielded 131, 117, and 77 MB/s
sequential reads near the beginning, middle, and end of the HDD. Three 15-second
random 4 KiB reads at queue depth one had a median of 61.43 IOPS and about
16.27 ms latency. These measurements do not characterize write performance.

SMART passed with zero reallocated, pending, uncorrectable, or CRC errors.
The disk had 19,546 power-on hours and about 434,263 head load cycles. A passing
SMART result does not establish future reliability. This is a 7200 RPM,
512e/4K-sector, SATA 6 Gb/s Travelstar 7K1000 with a 32 MB buffer.
The manufacturer's 24/7 Enhanced Availability specification applies to HTE
models, not this HTS model.

Use Zadar for agent sessions and moderate development workloads. Concurrent
dependency installs, checkouts, and builds will contend for HDD seeks. XFS
reflinks reduce copying but do not remove that latency. Nix build concurrency
starts at two jobs with two cores per job. Zadar is not registered as a remote
builder for other hosts.

## Network and power behavior

NetworkManager manages both interfaces. Ethernet routes have metric 100 and
Wi-Fi routes metric 600 for IPv4 and IPv6. The shared home Wi-Fi profile
autoconnects. This covers loss of the Ethernet link; it does not establish
failover when the link stays up but its upstream path fails. Both connections
depend on the same router.

First boot confirmed all three lid actions are `ignore` and all four sleep
targets are masked. With the owner-confirmed lid closed and installer USB
removed, two SSH checks 71 seconds apart showed the same boot ID, the ACPI lid
sensor reporting `closed`, Amp/T3 active, and no failed system or user units.
Amp's desktop mode is disabled.
An abrupt power loss stops this laptop immediately. XFS journal recovery does
not preserve unsynced application data. Automatic power-on after AC restoration
is not verified and requires a supported BIOS setting or another hardware
recovery mechanism.

## Installation verification

Clan's `disko,install` phases completed successfully, with `CLAN_NO_COMMIT=1`,
`--flake path:.`, `--build-on local`, `--update-hardware-config none`, and
`--no-persist-state`. The HGST serial and capacity were checked immediately
before formatting. No other machine was deployed.

The installed root is XFS on the HGST's second partition, with `reflink=1` and
`crc=1`; its first partition is the FAT32 ESP. The running system matches the
built NixOS toplevel. First boot confirmed Ethernet/Wi-Fi default route metrics
100/600 for IPv4 and IPv6, both connections autoconnecting, SSH and tailscaled
active, zstd zram of approximately 5.8 GiB, and the `powersave` governor.
There were no failed system units.

The agents checkout and sync completed successfully. The owner authenticated
Amp, and its runner registered as `zadar` and served its configured directories.
T3's bootstrap completed, installed `t3@0.0.46-nightly.20261009.2886`, applied
the fleet settings and gateway model catalog, and started `t3code.service`.
Both services were active with no failed user units. T3 returned HTTP 200 over
loopback and HTTPS through `https://zadar.trex-gamut.ts.net:8443/` on the tailnet.
Tailscale reported `Running` with no health warnings; Solna's gateway responded.

The initial tool refresh timed out installing Codex and OMP under the shared
two-minute installer limit. Their subsequent real CLI launches completed the
cached installations and returned `codex-cli 0.162.1` and `omp/18.8.7`.

Ventoy's partition table, first-MiB hash, and complete EFI-partition hash matched
before and after installation. Its block-device counter remained at zero
sectors written throughout the live boot. Firmware selected the HGST ESP and
the installed system booted while the USB remained connected.

## Remaining commissioning checks

- With local console access available, unplug Ethernet, verify Wi-Fi access,
  reconnect Ethernet, and confirm it becomes preferred again. Both interface
  addresses were reachable separately on first boot; cable-loss failover was
  not physically tested.
- Enter the BIOS with F2 at startup and inspect **Restore AC Power Loss**,
  **AC Back**, or **Power On AC**. Record the actual option and available
  settings. Firmware inspection was deferred until after installation; no
  power-cut test has been performed.

Adding the admin age recipient re-encrypts repository secrets; it does
not deploy those secrets or activate changes on any machine.

## Evidence

Hardware inventory is stored in `facter.json`. Raw SMART and read benchmark
outputs from this session are in `/tmp/zadar-evaluation.0IZo4c3P/` on the
preparation host; that temporary directory is not a permanent archive.
Installation and first-boot evidence is in `/tmp/zadar-install.log`,
`/tmp/zadar-installed-disk-efi.txt`, `/tmp/zadar-usb-before-verified.txt`,
`/tmp/zadar-usb-after.txt`, `/tmp/zadar-firstboot.txt`, and
`/tmp/zadar-runtime.txt` on that host. Closed-lid observations are in
`/tmp/zadar-closed-lid-verification.txt`; the commissioning record is
`/tmp/zadar-install-verification.txt`.
