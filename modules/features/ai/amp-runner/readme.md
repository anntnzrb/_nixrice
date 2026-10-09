# Amp runner

Import `inputs.self.homeModules.amp-runner` (or the NixOS module, which routes it) to run `amp-runner`, an Amp runner identified by the machine's hostname, through the agents-managed `amp` wrapper. It serves checkouts under `~/repos` and the agents checkout.

On Linux the runner starts with `--desktop`, a private headless desktop that needs `labwc`, `wlr-randr` and `ffmpeg`; the NixOS module installs them and enables lingering so the runner survives logout. On Darwin the flag is omitted because it would share the Mac's real screen. Check readiness with `amp runner desktop status`. `liberion.ai.amp-runner.desktop` (default: Linux) turns the flag off on a host.

## Updates

The agents-managed package refresher updates the cached release every 15 minutes. The wrapper uses that cache when a process starts, but the runner keeps the executable it started with. The hourly `amp-runner-update` job (`lib.liberion.idleRestartJob`, kind `amp`, script `modules/features/ai/idle-restart.py`) restarts the service when the version directory of the running executable differs from the wrapper's `amp --version` and no thread is active. A thread is active when the runner log shows activity in the last 15 minutes, or an unfinished turn in the last two hours. An unreadable log never restarts.

Linux runs the first check five minutes after the user manager starts, then one hour after each check finishes. Darwin runs it at load and every hour. The native `amp.runner.autoUpdate.enabled` setting belongs to `harnesses/amp/settings.json` in the agents repository; disable it there to make this Rice job the sole runner updater. This module does not override that sync-managed file.

Inspect: `systemctl --user status amp-runner.service amp-runner-update.timer` and `journalctl --user -u amp-runner-update.service` on Linux; `~/Library/Logs/amp-runner.log` and `~/Library/Logs/amp-runner-update.log` on Darwin. The runner's own log is `~/.cache/amp/logs/runner-agents.log`.

## Upstream

Amp is closed source; the CLI ships as the npm package `@ampcode/cli`. Reference: <https://ampcode.com/manual>.
