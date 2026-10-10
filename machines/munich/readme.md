# Munich

## Specs

| Component            | Desc                                                |
| -------------------- | --------------------------------------------------- |
| **CPU**              | Intel Core i5-12400                                 |
| **GPU (integrated)** | Intel UHD Graphics 730                              |
| **GPU (dedicated)**  | NVIDIA GTX 1080 8GB                                 |
| **Motherboard**      | Asus PRIME B660-PLUS D4 ATX LGA1700                 |
| **Cooler**           | Cooler Master Hyper 212 BE                          |
| **RAM**              | 32 GB DDR4-3600                                     |
| **Storage**          | XPG GAMMIX S11 Pro 512 GB                           |
| **Power Supply**     | EVGA BR 700 W 80+A                                  |
| **Case**             | Corsair 4000D ATX                                   |

## Role

Always-on NixOS server (tags `server`, `headless`, `nvidia`), whole-disk XFS via disko, `systemd-boot`, and remote builder for the Macs.

The hardware runs Debian with the CLIProxyAPI gateway and Hermes. This directory
is its NixOS target state: `clan machines update` and `just deploy` must not
target it until it is installed with this configuration. Its
`~/.ssh/authorized_keys` is maintained by hand until the migration.

## Peripherals

| Component   | Desc                                |
| ----------- | ----------------------------------- |
| **Monitor** | Asus VG245H 24\" 1920x1080 75 Hz    |
