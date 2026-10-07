# Paseo

Import `inputs.self.nixosModules.paseo` or `inputs.self.darwinModules.paseo` (both route the home part) to run `paseo`, the Paseo agent daemon, through the agents-managed `paseo` wrapper. It listens on `127.0.0.1:6767` with the relay off. The unit's `PASEO_*` variables override `~/.paseo/config.json`, which the daemon and its clients own; nothing here writes that file.

The system module publishes the daemon to the tailnet with Tailscale Serve on HTTPS port 6767 (`liberion.network.tailscale.expose.paseo`). On NixOS it also enables lingering so the daemon survives logout; on Darwin the launchd agent runs while the user is logged in.

Set `liberion.ai.paseo.autostart = false` (Linux) to keep the unit installed but out of `default.target`: start it with `systemctl --user start paseo.service`. Switching to it does not stop a running daemon.

## Updates

The wrapper installs the newest release on every launch, but the daemon keeps its version until it restarts. The nightly `paseo-update` job (`lib.liberion.idleRestartJob`, kind `paseo`, script `modules/features/ai/idle-restart.py`) restarts the service when `paseo --version` differs from the running daemon's `daemonVersion` and no agent is initializing or running. An unreadable status or agent listing never restarts. Without autostart the job runs only while `paseo.service` is active, so it never starts a stopped daemon.

## Operate

- Control the daemon through its service, never `paseo daemon start` or `stop`: a second supervisor takes `~/.paseo` and the service crash-loops. `paseo reload` and `paseo daemon restart` are safe.
- Enable a provider: `paseo daemon config set agents '{"providers":{...}}'` replaces the whole object, so merge `paseo daemon config get agents.providers` into it first, then `paseo reload`.
- Select a metadata model the gateway serves under **Settings → Host → Metadata → Manual**; the built-in choice can pick models the gateway rejects.
- Connect: browser `https://<host>.<tailnet>.ts.net:6767/`; app **Add host → Direct connection** with that host, port 6767, SSL on; CLI from another machine `paseo --host ssh://<host> ls`. Never pair through the relay.
- Do not install Paseo's own skills from its settings: the installer writes into harness skill directories that agents sync owns.

Inspect: `systemctl --user status paseo.service paseo-update.timer` and `journalctl --user -u paseo-update.service` on Linux; `~/Library/Logs/paseo.log` and `~/Library/Logs/paseo-update.log` on Darwin; `tailscale serve status` on both.

## Upstream

Source: <https://github.com/getpaseo/paseo>.
