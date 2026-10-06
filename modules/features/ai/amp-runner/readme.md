# Amp runner

Import `inputs.self.homeModules.amp-runner` (or the NixOS module, which routes it) to run `amp-runner`, an Amp runner identified by the machine's hostname. It serves checkouts under `~/repos` and the agents checkout through the agents-managed `amp` wrapper, so it imports `ai-agents`.

On Linux the runner starts with `--desktop`, a private headless desktop that needs `labwc`, `wlr-randr` and `ffmpeg`; the NixOS module installs them and enables lingering so the runner survives logout. On Darwin the flag is omitted because it would share the Mac's real screen. Check readiness with `amp runner desktop status`.

The wrapper installs new releases on launch, but the running runner keeps its version until it restarts. The nightly `amp-runner-update` job runs `sync job amp-runner-update`, which restarts it onto the newest cached release only when it is behind and idle; busy and idle rules live in agents sync.

Inspect: `systemctl --user status amp-runner.service amp-runner-update.timer` and `journalctl --user -u amp-runner-update.service` on Linux; `~/Library/Logs/amp-runner.log` and `~/Library/Logs/amp-runner-update.log` on Darwin. The runner's own log is `~/.cache/amp/logs/runner-agents.log`.
