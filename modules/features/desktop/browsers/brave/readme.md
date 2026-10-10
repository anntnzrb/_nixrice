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
- The cask preserves Brave's vendor signature, auto-updates, and matches what
  Brave ships. Stripping a signed app can damage its signature and prevent
  profile access
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
| `BackgroundTabFreezingEnabled` | `true` | Freeze background tab timers (Chrome 155+) |
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

## Long uptime

No setting fixes PartitionAlloc/V8 heap fragmentation during long uptime.
Quit and reopen weekly; session restore brings tabs back lazily.
`brave://discards` shows what Memory Saver has discarded.
