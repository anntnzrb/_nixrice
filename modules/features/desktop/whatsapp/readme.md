# whatsapp

Home Manager feature (darwin only). One launchd agent, `whatsapp-idle-guard`, polls every
`pollSeconds` and quits WhatsApp Desktop only while it blocks sleep. Options live under
`liberion.desktop.whatsapp` in `home.nix`.

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

WhatsApp's processes are every process running from `appPath`: the app, its
`ServiceExtension`, and an app that keeps running after Quit. Each poll, in order:

1. No WhatsApp process: exit.
2. A WhatsApp process has a **coreaudiod** audio session (`Created for PID: <pid>` under a
   `pid N(coreaudiod)` line in `pmset -g assertions`): treat as a call, exit. Only coreaudiod
   counts: runningboardd's `Application.*` assertion also carries `Created for PID` and exists
   whenever the app runs.
3. The user touched the keyboard or trackpad within `sleepBlockMinutes` (60 s when the lid is
   closed, per `AppleClamshellState`): exit.
4. Kill every WhatsApp process (SIGTERM, then SIGKILL after `killGraceSeconds`) when a
   `PreventUserIdleSystemSleep` or `PreventSystemSleep` assertion held at least as long is owned
   by a WhatsApp process, or is a `cameracaptured-*` assertion created for one. The kill log line
   records the assertion type and name.

WhatsApp is never quit for being unused, so it keeps delivering notifications. Idle time comes
from `HIDIdleTime` in `ioreg`.

## Deliberately not done

- No quit on display sleep or system sleep. The old sleepwatcher hook fired on display-off,
  including brief flaps, causing needless cold starts.
- No revoking of camera permission. It would stop the leak but also video calls.
- No pmset changes (`powernap`, `womp`, `disksleep`); they are system-wide and unrelated to WhatsApp.

## Limitations

A video call without a coreaudiod audio session can look idle. The idle-user
check reduces the risk of interrupting an active user.

## Testing

Never test against the live WhatsApp. Point `appPath` at a throwaway `.app` directory whose
`Contents` holds copies of `/bin/sleep`, shim `pmset` and `ioreg` with `sed` on the script's
absolute paths, then feed canned assertion text and check kill or keep.

Inspect assertions with `pmset -g assertions | grep -i whatsapp` and
`pmset -g log | grep -i cameracaptured`.
