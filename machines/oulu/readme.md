# Machine Architecture: `oulu`

`oulu` is a 24/7 headless home server and remote build box running on repurposed Lenovo V15 G4 IRU laptop hardware.

---

## 1. Hardware & Platform

| Component | Specification | Operational Role |
|---|---|---|
| **Chassis / Model** | Lenovo V15 G4 IRU | Repurposed laptop running headless 24/7. |
| **CPU** | Intel Core i7-1355U (Raptor Lake) | 10 Cores / 12 Threads (2 Performance cores + 8 Efficient cores). |
| **RAM** | 24 GB DDR4 (8 GB Soldered + 16 GB SO-DIMM) | Backed by 12 GB zstd ZRAM swap. |
| **Storage** | 1 TB NVMe SSD (`SKHynix_HFS001TEJ4X112N`) | GPT layout formatted with XFS + Reflinks. |
| **Networking** | Realtek RTL8111 (Gigabit Ethernet) + Realtek RTL8852BE (Wi-Fi 6) | Redundant dual-interface with automatic Ethernet priority. |

---

## 2. Kernel Selection & Tuning

### Why Mainline (`pkgs.linuxPackages_latest`)?
* **Intel Thread Director (ITD)**: Hybrid P/E core architectures require modern kernel scheduler support. Mainline Linux provides proper task placement so Nix compilations leverage P-cores while background services utilize E-cores.
* **Driver Maturity**: Contains current upstream drivers for the `rtw89_8852be` Wi-Fi chip and Raptor Lake Iris Xe graphics.
* **Hydra Binary Cache**: Zero local kernel compilation overhead and instant updates.

### Native XanMod-Grade Sysctl Tuning (`server` profile, `modules/profiles/server`)
Rather than maintaining a custom forked kernel, the following sysctls are applied:
* `net.ipv4.tcp_congestion_control = "bbr"` & `net.core.default_qdisc = "cake"`: High throughput, minimal bufferbloat for Tailscale gateway traffic and WAN transfers.
* `net.ipv4.tcp_fastopen = 3`: Lowers TCP handshake latency for incoming and outgoing connections.
* `kernel.nmi_watchdog = 0`: Disables the hardware timer interrupt watchdog to prevent unnecessary CPU wakeups and reduce laptop thermal overhead.
* `vm.dirty_background_ratio = 5` & `vm.dirty_ratio = 10`: Flushes dirty pages to NVMe storage early and incrementally, preventing writeback stalls during heavy disk I/O.

---

## 3. Storage & Filesystem (`disko-xfs` feature, `modules/features/hardware/disko-xfs`)

* **Partition 1 (1 GB FAT32 ESP)**: Mounted at `/boot` (`systemd-boot`, EFI variables enabled).
* **Partition 2 (100% Remaining XFS)**: Mounted at `/` with `crc=1,reflink=1`.
  * **Why XFS Reflinks?**: Enables instant zero-copy file cloning for Nix builds, container layers, and state manipulation without the heavy RAM and CPU overhead of ZFS/Btrfs copy-on-write trees.

---

## 4. Memory & Swap Architecture (`server` profile, `modules/profiles/server`)

* **ZRAM Swap (`zstd`)**: Allocates 50% of RAM (12 GB) as compressed swap with priority 100, yielding ~36+ GB effective memory.
* `vm.swappiness = 100`: Aggressively pages idle anonymous memory into fast Zstd compressed RAM, freeing physical RAM pages for the Linux page cache and active Nix builds.
* `vm.page-cluster = 0`: Enables single-page compressed I/O without multi-page readahead penalties.

---

## 5. Networking & Remote Access

* **Tailscale**: Enabled with `--ssh=false`, `--hostname=oulu`, and route acceptance (`useRoutingFeatures = "client"`). Tailnet SSH uses OpenSSH and fleet keys.
* **Dual-Interface Failover**:
  * Physical Gigabit Ethernet (`enp3s0`): Primary route (metric `100`).
  * Wi-Fi (`wlp2s0`): Automatic fallback route (metric `600`).
  * `nmtui` / `nmcli`: Available for headless emergency wireless configuration.
  * The `server-laptop` profile supplies NetworkManager-only management and
    route metrics by device type for IPv4 and IPv6. Clan assigns the shared
    home Wi-Fi credentials to that tag. Both links can stay connected;
    Ethernet is preferred. This covers cable/link loss, not an upstream outage
    while the Ethernet link stays up.
* **OpenSSH**: Strict ED25519 public key authentication for the admin user only; root login and password authentication are disabled. Clan deploys connect as the admin user and escalate with `sudo`.

---

## 6. Secrets & Fleet Management

* **Clan 26.05 Vars**: Secrets (root password, host SSH keys, Age encryption keys) are generated deterministically and encrypted with SOPS/Age under `vars/per-machine/oulu/`.
* **Modular Flake Composition**: `server` supplies power and memory policy,
  `headless` disables the graphical session, and `server-laptop` supplies the
  shared laptop network policy. Machine-specific services and build limits
  stay in `configuration.nix`; Amp's desktop mode is disabled.

## Commissioning audit

The read-only audit on 2026-10-09 found no Wi-Fi profile and both NetworkManager
and systemd-networkd active before the shared-profile change. The target above
corrects those findings. Oulu is a work-owned machine: deployment requires
explicit owner authorization. Closed-lid continuity,
physical cable-loss recovery, and power-on after battery exhaustion remain
unverified.
