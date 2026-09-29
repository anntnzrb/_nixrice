# whatsapp

Home Manager feature (darwin only). One launchd agent, `whatsapp-idle-guard`, polls every
`pollSeconds` and quits WhatsApp Desktop when it is unused or when it blocks sleep. Options live
under `liberion.desktop.whatsapp` in `home.nix`.

Last researched: 2026-09-29 (macOS 27.0 build 26A428, WhatsApp 26.35.74, MacBook, no external display).

## The problem

WhatsApp Desktop for Mac (a Catalyst app) has a long-running bug: it can hold a sleep-preventing
power assertion, so the Mac does not idle-sleep and the battery drains, worst with the lid closed
in a bag. The assertion people report is the camera one:

```
pid 15049(WhatsApp): [0x0004cdcf0001a17c] 04:06:29 PreventUserIdleSystemSleep named: "cameracaptured-idleSleepPreventionForBWFigCaptureDevice"
```

The owner is WhatsApp's own pid. It is held for hours, with no call in progress. The name points at
the AVFoundation capture-device layer (`cameracaptured`); why WhatsApp opens a capture device
outside a call is unknown [?!]. There is no fix from Meta. Every workaround is "quit the app".

## Sources (as found 2026-09-29 via Parallel search)

| Date | Source | What it says |
| --- | --- | --- |
| 2025-11-12 (thread start; posts to 2026-02-17) | [MacRumors: WhatsApp preventing sleep?](https://forums.macrumors.com/threads/whatsapp-preventing-sleep.2471010/) | Exact `pmset` line above, held 4h+. Sleep worked again after some update or macOS 26.3, then "one more update from Meta ruined this again"; quitting WhatsApp was the only fix. Assertion behaviour changes between WhatsApp releases |
| 2025-09-22 (thread start) | [MacRumors: macOS Tahoe Bug Reports](https://forums.macrumors.com/threads/macos-tahoe-bug-reports.2467138) | Sleep Aid shows the camera assertion while WhatsApp runs. **Conflicting claim in the same thread:** the camera name "does not actually prevent sleep"; the real blocker is the app's own `Application.Net.whatsapp.WhatsApp` assertion. Fix: quit WhatsApp or `pmset sleepnow` |
| date not returned (Tahoe era) | [r/whatsapp: WhatsApp prevents MacBook Air (Tahoe) from sleeping](https://www.reddit.com/r/whatsapp/comments/1oys624/bug_whatsapp_prevents_macbook_air_macos_tahoe) | Same assertion on M2 Air. Restart, reinstall, reboot, camera permission and closing call windows did not help |
| date not returned | [david-solo/AutoCloseWhatsApp](https://github.com/david-solo/AutoCloseWhatsApp) | Same design as the old sleepQuit hook here: sleepwatcher runs a script that quits WhatsApp on lid close, sleep, logout |
| date not returned | [gist riandoza: clamshell battery drain](https://gist.github.com/riandoza/49f551e584d30bf6ea6015be49486820) | Lists the WhatsApp camera bug as a cause. Suggests `pmset -a disksleep 10 powernap 0 womp 0` and revoking camera permission |
| date not returned | [douglascorrea/whatsapp-monitor](https://github.com/douglascorrea/whatsapp-monitor) | Idle auto-close, for presence ("appears online") rather than sleep |
| 2026-05-07 | [sozercan/kaset#244](https://github.com/sozercan/kaset/issues/244) | Different app, same symptom on macOS 26: assertion plus constant DarkWakes on battery |
| date not returned | [Apple Community 255869937](https://discussions.apple.com/thread/255869937) | WhatsApp draining an M1 Max on Sonoma 14.6.1. Suggests the drain predates Tahoe |
| 2023-01 / 2023-02 | Apple Community [254537445](https://discussions.apple.com/thread/254537445), [254606353](https://discussions.apple.com/thread/254606353) | iPhone, not Mac: WhatsApp leaves the camera indicator on after video calls. Only weak evidence that the camera-not-released bug is old |
| not verified | [glaeda#507](https://github.com/teamleaderleo/glaeda/issues/507) | Quotes Apple as saying `PreventUserIdleSystemSleep` still allows sleep on lid close, menu sleep and low battery. This is the source for "lid close beats the assertion"; I did not find the Apple header myself |

## What was checked on this machine (2026-09-29)

- `pmset -g log`, 2026-09-22 to 09-29: **zero** `cameracaptured` entries and no WhatsApp
  `PreventUserIdleSystemSleep`. The only WhatsApp assertion is `net.whatsapp.idletimer`
  (`PreventUserIdleDisplaySleep`): 8 created and released, each held 0 to 59 s. That is a normal
  idle timer, not the leak.
- 19 `Clamshell Sleep` events in the same window (18 `Entering Sleep`, 1 `Entering DarkWake`
  followed by sleep 9 minutes later). Each ended in sleep. Some had a WindowServer
  `PreventSystemSleep` at the time, and it cleared.
- WhatsApp has entitlements `com.apple.security.device.camera` and `device.audio-input`, plus
  `NSCameraUsageDescription`. Its TCC camera grant could not be read (no TCC.db under
  `~/Library/Application Support`), so **permission state is unknown**.
- `FrontCameraActive` and `FrontCameraStreaming` are `No`. `cameracaptured` (pid 569) runs at 0% CPU.
- An older sleepwatcher hook quit WhatsApp on every display-off (its log shows kills on 2026-09-28,
  and it keeps running until the redesign is deployed). That may have hidden the bug, so "not seen
  here" is weak evidence. The bug may still exist on 26.35.74 / macOS 27.

## How the guard decides (`whatsapp-idle-guard.sh`)

Each poll, in order:

1. Not running: clear state, exit.
2. WhatsApp has a **coreaudiod** audio session (`Created for PID: <pid>` under a `pid N(coreaudiod)`
   line in `pmset -g assertions`): treat as a call, refresh the last-active stamp, exit. Only
   coreaudiod counts: runningboardd's `Application.*` assertion also carries `Created for PID`
   and exists whenever the app runs.
3. Frontmost and the user touched the keyboard or trackpad in the last 120 s: refresh stamp, exit.
4. Kill (SIGTERM, then SIGKILL after `killGraceSeconds`) when either holds:
   - a `PreventUserIdleSystemSleep` or `PreventSystemSleep` assertion for at least
     `sleepBlockMinutes` (60 s when the lid is closed, per `AppleClamshellState`) is owned by
     WhatsApp's pid, or is a `cameracaptured-*` assertion created for WhatsApp's pid, and the user
     has been idle at least as long. The kill log line records the assertion type and name;
   - the last-active stamp is older than `timeoutMinutes`.

Idle time comes from `HIDIdleTime` in `ioreg`, frontmost app from `lsappinfo front`.

## Deliberately not done

- No quit on display sleep or system sleep. The old sleepwatcher hook fired on display-off,
  including 1-second flaps, causing needless cold starts against a 3.2 GB data directory.
- No revoking of camera permission. It would stop the leak but also video calls.
- No pmset changes (`powernap`, `womp`, `disksleep`); they are system-wide and unrelated to WhatsApp.

## Open questions

1. Does the camera assertion still occur on WhatsApp 26.35.74 / macOS 27? Nothing seen locally.
2. Which assertion really blocks sleep: the camera one, or `Application.Net.whatsapp.WhatsApp`
   (see the Tahoe thread)? The guard matches by owner pid and type, so it catches both. The kill
   line in `~/Library/Logs/rice/whatsapp-idle-guard.log` now names the assertion, so the first
   real hit answers this: copy it into "Sources".
3. The `cameracaptured`-owned shape (WhatsApp only in `Created for PID`) is handled but only
   against a made-up fixture: no real output of it exists in the sources or on this machine.
   Replace the fixture when a real one turns up.
4. A video call with no audio session would look idle. Unlikely; the idle-user check softens it.
5. What triggers WhatsApp to open a capture device outside a call? Unknown.

## Testing

Never test against the live WhatsApp; use TextEdit as the target. Shim `pmset`, `ioreg` and
`lsappinfo` with `sed` on the script's absolute paths, then feed canned assertion text and check
kill or keep. The 2026-09-29 run covered the leak (with and without an active user), the 60 s
lid-closed threshold, a display-only assertion, a lookalike pid prefix (`9<pid>`), the 60-minute
timeout, call detection, SIGTERM-ignoring processes, and a garbage state file. The harness is not
in the repo.

Real check for the bug when it happens: `pmset -g assertions | grep -i whatsapp` and
`pmset -g log | grep -i cameracaptured`. Paste the owner line into "Sources" here.
