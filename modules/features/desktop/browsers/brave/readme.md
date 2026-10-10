# brave

Brave, tuned for a browser that stays open for weeks.

- `darwin.nix`: Homebrew cask `brave-browser` + enterprise policies written to
  `/Library/Managed Preferences/com.brave.Browser.plist` on activation
- `home.nix`: Linux only. Home Manager `programs.brave` with `commandLineArgs`

Check what Brave actually applied: `brave://policy` (every key should show
`OK`, source `Platform`, level `Mandatory`).

## Why a cask and not `pkgs.brave` on darwin

- Home Manager wraps only `$out/bin/brave`. Dock, Finder, Spotlight and Raycast
  launch `Brave Browser.app/Contents/MacOS/Brave Browser` through LaunchServices,
  so `commandLineArgs` never apply on macOS. Policies apply to every launch
- nixpkgs Brave on darwin has broken twice in 2026:
  - NixOS/nixpkgs#541861: stripping damaged the code signature, macOS 27 denied
    profile access. Fixed by #560971 (2026-09-07): signed `.dmg` + `dontStrip`
  - NixOS/nixpkgs#563147: the `.dmg` ships a `" "` symlink to `/Applications`
    that broke `unpackPhase`. Fixed by #563748 (2026-09-16)
- Even when it evaluates, nixpkgs lags the cask (`pkgs.brave` 1.95.104 vs cask
  1.96.59 on 2026-09-28). The cask is signed, auto-updates, and matches what
  Brave ships
- No Nix flake tracks Brave releases for darwin. The community ones
  (`drishal/brave-browser-flake`, `Daniel-42-z/brave-origin-flake`) are Linux
  only. Brave publishes APT/RPM repos and `.dmg`s, nothing Nix-specific

## Policies

Chromium definitions: `components/policy/resources/templates/policy_definitions/Miscellaneous/<Name>.yaml`
in chromium/chromium. Brave definitions: `browser/policy/brave_simple_policy_map.h`
in brave/brave-core.

| Policy | Value | Why |
| --- | --- | --- |
| `HighEfficiencyModeEnabled` | `true` | Memory Saver on (Chrome 108+) |
| `MemorySaverModeSavings` | `2` | Maximum: discard inactive tabs aggressively (Chrome 126+) |
| `BatterySaverModeAvailability` | `1` | Battery Saver below the low-battery threshold; `2` is deprecated since M121 |
| `BackgroundTabFreezingEnabled` | `true` | Freeze background tab timers. Chrome 155+: ignored on Brave 1.96 (Chromium 154) until the next rebase |
| `BackgroundModeEnabled` | `false` | Nothing keeps running after Cmd+Q |
| `NetworkPredictionOptions` | `2` | No speculative preconnect/prefetch; first loads may be slightly slower |
| `BraveAIChatEnabled` | `false` | Leo off |
| `BraveNewsDisabled`, `BraveRewardsDisabled`, `BraveTalkDisabled`, `BraveVPNDisabled`, `BraveWalletDisabled` | `true` | Feature bloat off |
| `BraveP3AEnabled`, `BraveStatsPingEnabled`, `BraveWebDiscoveryEnabled` | `false` | Telemetry and background pings off |

## Rejected

- `--enable-gpu-rasterization`: default on Apple Silicon already
- `--enable-zero-copy`: default on macOS (`content/browser/gpu/compositor_util.cc`,
  `IsZeroCopyUploadEnabled` returns `!HasSwitch(kDisableZeroCopy)` under `IS_MAC`)
- `--disable-features=BackForwardCache`: back/forward becomes full reloads;
  Memory Saver already reclaims discarded tabs
- `--enable-features=InfiniteTabsFreezing`: internal experiment; the
  `BackgroundTabFreezingEnabled` policy is the supported switch
- `--disable-background-networking`: kills the component updater (Shields
  lists, CRLSet, extension updates)
- `--renderer-process-limit`: forces process sharing, more jank and crash blast radius
- `BraveLocalAIEnabled`: not verified against brave-core

## Long uptime

No setting fixes PartitionAlloc/V8 heap fragmentation over 30-60 days.
Quit and reopen weekly; session restore brings tabs back lazily.
`brave://discards` shows what Memory Saver has discarded.

## Upstream

- Chromium policy list: https://chromeenterprise.google/policies/
- brave-core: https://github.com/brave/brave-core (`browser/policy/`)
- Brave group policy docs: https://support.brave.com/hc/en-us/articles/360039248271-Group-Policy
- Home Manager module: `modules/programs/chromium.nix` in nix-community/home-manager
- nixpkgs package: `pkgs/applications/networking/browsers/brave/`
