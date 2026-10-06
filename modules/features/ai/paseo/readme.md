# Paseo

Import `inputs.self.nixosModules.paseo` or `inputs.self.darwinModules.paseo` (both route the home part) to run `paseo`, the Paseo daemon, through the agents-managed `paseo` wrapper. It listens on `127.0.0.1:6767` with the relay off; the unit's `PASEO_*` variables override `~/.paseo/config.json`, which the daemon and its clients own.

The system module publishes the daemon to the tailnet with Tailscale Serve on HTTPS port 6767 (`liberion.network.tailscale.expose.paseo`). On NixOS it also enables lingering so the daemon survives logout; on Darwin the launchd agent runs while the user is logged in.

Control the daemon through its service, not `paseo daemon start` or `stop`: a second supervisor owns `~/.paseo` and makes the service crash-loop. The nightly `paseo-update` job runs `sync job paseo-update`, which restarts the daemon onto the newest release only when no agent is mid-turn. Host setup and client connection: `docs/paseo.md` in the agents repository.

Inspect: `systemctl --user status paseo.service paseo-update.timer` on Linux; `~/Library/Logs/paseo.log` on Darwin; `tailscale serve status` on both.
