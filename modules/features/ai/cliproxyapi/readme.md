# CLIProxyAPI

Import `inputs.self.nixosModules.cliproxyapi` on the Linux gateway host. It runs a NixOS system service under a dedicated `cliproxyapi` user, with state under `/var/lib/cliproxyapi`.

## Exposure

The backend listens on its configured port on every interface, and the firewall opens that port only on `tailscale0`. Tailnet clients reach it directly, without authentication. The module publishes `auth-gateway.py` through Tailscale Funnel for Amp, which requires a hosted endpoint. That gateway accepts inference only with `CLIPROXY_FUNNEL_TOKEN` and refuses management routes. Never expose the backend directly through Funnel.

## Configuration and secrets

Nix generates the public YAML from `settings.nix`. Before every start, `configure.py` merges it with `/var/lib/cliproxyapi/secrets.json`, which is loaded as a systemd credential, and writes the private configuration under `/run/cliproxyapi`.

- `x-credential-pool` expands to the API keys of the named pool. Every pool in the secrets file must be referenced.
- `x-model-discovery` reads the pool's `{base-url}/models` with its first key. `x-model-exclude` removes model IDs that another section already serves. The last successful listing is stored in `/var/lib/cliproxyapi/models.json`; an unreachable upstream keeps its cached models.

Provision `secrets.json` and the OAuth credential files under the state directory, owned by `cliproxyapi` with mode `0600`. They are runtime state: the proxy renews OAuth files itself, so deployments never overwrite them. Without `secrets.json` the services do not start; start them after provisioning.

## Updates

At 04:00 daily, `cliproxyapi-update` installs the latest checksum-verified release and refreshes the model catalog. It restarts the backend only when the selected release or the catalog changed. A restart can interrupt in-flight requests. Failed downloads keep the selected release and fail the unit visibly.

Inspect with `systemctl status cliproxyapi`, `systemctl list-timers cliproxyapi-update`, and `journalctl -u cliproxyapi`.
