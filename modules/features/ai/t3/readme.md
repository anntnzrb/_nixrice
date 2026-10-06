# T3 Code

Import `inputs.self.nixosModules.t3` on a Linux host. T3 writes and supervises its own `t3code.service`; this module only schedules agents sync to install and maintain it:

- `t3-update`, nightly: `sync t3 auto-update` installs T3 on a fresh host, then moves it to the head of the release channel set in the agents repository, postponing while a thread runs.
- `t3-refresh-models`, every 15 minutes: `sync t3 refresh-models` keeps the Claude model list in step with the gateway catalog.

The NixOS module publishes the server's default port 3773 to the tailnet with Tailscale Serve on HTTPS port 8443 (`liberion.network.tailscale.expose.t3`) and enables lingering. Pair a device with `sync t3 pair`, as described in `docs/t3.md` in the agents repository.

There is no Darwin module: the T3 desktop app runs its own server in `~/.t3`, which a background service would share.

Inspect: `systemctl --user status t3code.service t3-update.timer t3-refresh-models.timer` and `journalctl --user -u t3-update.service`.
