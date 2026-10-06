# T3 Code

Import `inputs.self.nixosModules.t3` or `inputs.self.darwinModules.t3`. T3 writes and supervises its own service (`t3code.service` on Linux, launchd `com.t3tools.t3code.service` on Darwin); this module only schedules agents sync to install and maintain it:

- `t3-update`, nightly: `sync t3 auto-update` installs T3 on a fresh host, then moves it to the head of the release channel set in the agents repository, postponing while a thread runs.
- `t3-refresh-models`, every 15 minutes: `sync t3 refresh-models` keeps the Claude model list in step with the gateway catalog.

The system module publishes the server's default port 3773 to the tailnet with Tailscale Serve on HTTPS port 8443 (`liberion.network.tailscale.expose.t3`); on NixOS it also enables lingering. Pair a device with `sync t3 pair`, as described in `docs/t3.md` in the agents repository.

On a Darwin host with the T3 desktop app, the app is a client of this service. Turn off **Settings → Connections → Local environment** so the app stops starting its own server in `~/.t3`, then add the host's environments. The app's settings files and the service's data share `~/.t3/userdata` without overlapping.

Inspect: `systemctl --user status t3code.service t3-update.timer t3-refresh-models.timer` and `journalctl --user -u t3-update.service` on Linux; `sync t3 status` and `~/Library/Logs/t3-update.log` on Darwin.
