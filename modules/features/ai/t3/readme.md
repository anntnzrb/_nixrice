# T3 Code

Import `inputs.self.nixosModules.t3` or `inputs.self.darwinModules.t3`. T3 writes and supervises its own user service (`t3code.service` on Linux, launchd `com.t3tools.t3code.service` on Darwin) and keeps its state in `~/.t3`. This module decides when that service updates, what its settings are, and how it is reached.

## Jobs

Both run `cli.py`, packaged as `t3ctl`, by its absolute Nix store path; the module
does not add it to the user's `PATH`. They start 5 minutes after the user session
does. Each host decides from its own state, so a busy host postpones while an
idle one updates.

- `t3-sync`, every 15 minutes, never restarts anything: merges server and desktop client settings and replaces the Claude instance's custom models with the non-Anthropic models the gateway lists. A deploy that changes settings reaches the host on the next run. Does nothing before T3 is installed.
- `t3-update`, hourly: installs T3 with `npx t3@<channel> service install` on a host without it. Otherwise it applies settings like `t3-sync`, then runs the installed `t3 update --yes --channel <channel>`, which exits without a restart when the service already runs the channel head; otherwise it verifies the release checksums, checks that the new runtime starts, and restarts the service. While any thread has an unsettled run in `userdata/statev2.sqlite`, it postpones the update; an unreadable database aborts it.

T3 has no unattended updater of its own: `t3 update` restarts the service without checking for running turns.

## Settings

`settings.nix` holds the declared server settings, the default of `liberion.ai.t3.settings`; a machine deep-merges host-specific keys into that option. Each run deep-merges them into `~/.t3/userdata/settings.json`; keys it does not set keep the value a client chose, and T3 reloads the file while running. Harnesses are found on the service's `PATH`, which includes the agents-managed wrappers in `~/.local/bin`. Check a key against `packages/contracts/src/settings.ts` upstream before adding it: T3 replaces an invalid file with defaults.

Keep `providerInstances.claudeAgent.config.homePath` unset. Setting it redirects
`CLAUDE_CONFIG_DIR` away from the agents-managed `~/.claude/settings.json`, so
the Bash timeout cap and tool hooks stop applying.

`followUpBehavior` belongs to `ClientSettings`, not the server settings.
`client-settings.json` holds the declared desktop preferences, including
`steer`: both jobs merge it into `~/.t3/userdata/client-settings.json`, preserving
undeclared preferences such as font sizes. Restart the desktop app after the
sync to load it. Steer interrupts the active tool call;
Queue waits for the whole turn to finish. Use Stop to request session
cancellation; do not rely on Steer to stop background Bash jobs.

Nix packages both declarations together. `t3ctl` takes the server declaration
through `--settings` and reads `client-settings.json` from the same directory.
The release channel, gateway, and job schedules are configured in `home.nix`.

Browser and mobile preferences are local to each client and do not sync from
that desktop file. Set them manually on every client:

- Browser: **Settings → General → Follow-up behavior → Steer**. Repeat for each
  browser profile and origin; the value lives in localStorage under
  `t3code:client-settings:v1`.
- Mobile: **Settings → Follow-ups → While the agent is running → Steer**. The
  value lives in the app's private preferences database.

The release channel (`--channel` in `home.nix`) is `nightly` or `stable`. Moving to an older channel head needs `t3 update --allow-downgrade` by hand.

## Access

The system module publishes port 3773 to the tailnet with Tailscale Serve on HTTPS port 8443 (`liberion.network.tailscale.expose.t3`); on NixOS it also enables lingering. On NixOS no login user may change Serve, so never pass `--tailscale` to T3 commands.

- Pair a device: `t3 pair --ttl 1h --label <device>`, then open `https://<host>.<tailnet>.ts.net:8443/pair#token=<token>` with the printed token.
- T3 Connect, so clients renew credentials through the relay instead of pairing again: `t3 connect link --headless`, approve the printed device code in a browser, `t3 service restart`, then `t3 connect status` must show `Environment link: provisioned`. The link lives in `~/.t3`.

Run `t3` as the installed runtime: `~/.t3/runtime/versions/<activeVersion>/t3`, with `activeVersion` from `~/.t3/runtime/service-state.json`.

On a Darwin host with the T3 desktop app, turn off **Settings → Connections → Local environment** so the app stops starting its own server in `~/.t3`, then add each host as an environment.

## Inspect and test

- Linux: `systemctl --user status t3code.service t3-update.timer t3-sync.timer`, `journalctl --user -u t3-update.service`.
- Darwin: `~/Library/Logs/t3-update.log`, `launchctl print gui/$(id -u)/com.t3tools.t3code.service`.
- Tests: `checks.python` (`just check`); in the dev shell, `pytest modules/features/ai/t3/tests`.

## Upstream

Source: <https://github.com/pingdotgg/t3code>. CLI commands live in `apps/server/src/cli/` (`update.ts`, `service.ts`, `connect.ts`, `pair.ts`), the settings schema in `packages/contracts/src/settings.ts`, user guides in `docs/user/`.
