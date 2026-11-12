# accra

NixOS-WSL distribution, portable to any x86_64 Windows host with WSL 2: a
development environment that also drives the Windows side through interop
(`powershell.exe`, `pwsh.exe`, `winget.exe` and the rest of the Windows `PATH`).
It has no hardware of its own: WSL supplies the kernel, networking, the GPU
driver (`/usr/lib/wsl/lib`) and `/etc/resolv.conf`, so nothing here depends on
the Windows machine it runs on.

- The image is built from this configuration, so the distro boots straight
  into it; there is no generic image to install first. GitHub release assets
  must stay under 2 GiB: check the asset size when adding packages to the base
  home or `essentials`
- Install: download `accra.wsl` from the `accra-latest` release, then in
  PowerShell `wsl --install --from-file accra.wsl --name accra` and
  `wsl --set-default accra`. Later changes: `sudo nixos-rebuild switch --flake
  <rice checkout>#accra` inside the distro
- The ssh-agent bridge talks to the Windows OpenSSH agent: enable it once in an
  elevated PowerShell with `Set-Service ssh-agent -StartupType Automatic` and
  `Start-Service ssh-agent`, then `ssh-add` the key on Windows
- `%UserProfile%\.wslconfig` is read by Windows before any distro starts, so it
  cannot come from this flake. Write it once per Windows host:

  ```ini
  [wsl2]
  networkingMode=mirrored
  dnsTunneling=true
  autoProxy=true

  [experimental]
  autoMemoryReclaim=gradual
  sparseVhd=true
  hostAddressLoopback=true
  ```

  `mirrored` shares the Windows network stack (LAN and Tailscale addresses,
  `localhost` both ways); it needs Windows 11 22H2 or later. Apply with
  `wsl --shutdown`
- `sparseVhd` only applies to newly created disks. An existing install
  converts once with `wsl --shutdown` then `wsl --manage accra --set-sparse
  true`; the weekly fstrim then hands freed space back to Windows
- Defender scans every VHDX read: from an elevated PowerShell,
  `Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\wsl"` and
  `Add-MpPreference -ExclusionProcess vmmem,vmmemWSL`
- Keep repos under the distro's ext4 (`~/src`), never `/mnt/c`: drvfs is a 9p
  share and every stat crosses the VM boundary
