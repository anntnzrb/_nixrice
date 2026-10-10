# whatsapp

Home Manager feature (darwin only). One launchd agent, `whatsapp-idle-guard`, polls every
`pollSeconds` and quits WhatsApp Desktop when it is unused or when it blocks sleep. Options live
under `liberion.desktop.whatsapp` in `home.nix`.

## The problem

WhatsApp Desktop for Mac (a Catalyst app) has a long-running bug: it can hold a sleep-preventing
power assertion, so the Mac does not idle-sleep and the battery drains, worst with the lid closed
in a bag. The assertion people report is the camera one:

`PreventUserIdleSystemSleep` named
`cameracaptured-idleSleepPreventionForBWFigCaptureDevice`, owned by WhatsApp's pid.
The assertion can persist with no call in progress. Its name points at the
AVFoundation capture-device layer (`cameracaptured`); the trigger outside a call
is unknown. Quitting WhatsApp releases the assertion.

WhatsApp declares camera and audio-input entitlements
(`com.apple.security.device.camera`, `com.apple.security.device.audio-input`)
and `NSCameraUsageDescription`.

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
  including brief flaps, causing needless cold starts.
- No revoking of camera permission. It would stop the leak but also video calls.
- No pmset changes (`powernap`, `womp`, `disksleep`); they are system-wide and unrelated to WhatsApp.

## Limitations

A video call without a coreaudiod audio session can look idle. The idle-user
check reduces the risk of interrupting an active user.

## Testing

Never test against the live WhatsApp; use TextEdit as the target. Shim `pmset`, `ioreg` and
`lsappinfo` with `sed` on the script's absolute paths, then feed canned assertion text and check
kill or keep.

Inspect assertions with `pmset -g assertions | grep -i whatsapp` and
`pmset -g log | grep -i cameracaptured`.
