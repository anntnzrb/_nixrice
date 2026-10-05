# CLIProxyAPI

Import `inputs.self.nixosModules.cliproxyapi` on the Linux gateway host. It runs a NixOS system service under a dedicated `cliproxyapi` user, with state under `/var/lib/cliproxyapi`.

## Exposure

The backend listens on its configured port on every interface, and the firewall opens that port only on `tailscale0`. Tailnet clients reach it directly, without authentication. The module publishes `auth-gateway.py` through Tailscale Funnel for Amp, which requires a hosted endpoint. That gateway accepts inference only with `CLIPROXY_FUNNEL_TOKEN` and refuses management routes. Never expose the backend directly through Funnel.

## Configuration and secrets

Nix generates the public YAML from `settings.nix`. Before every start, `configure.py` merges it with `/var/lib/cliproxyapi/secrets.json`, which is loaded as a systemd credential, and writes the private configuration under `/run/cliproxyapi`.

- `x-credential-pool` expands to the API keys of the named pool. Every pool in the secrets file must be referenced.
- `x-model-discovery` reads the pool's `{base-url}/models` with its first key. `x-model-exclude` removes model IDs that another section already serves. The last successful listing is stored in `/var/lib/cliproxyapi/models.json`; an unreachable upstream keeps its cached models.

Provision `secrets.json` in the state directory and the OAuth credential files in its `auth/` subdirectory, owned by `cliproxyapi` with mode `0600`. The proxy treats every `.json` in `auth/` as a credential, so nothing else belongs there. Both are runtime state: the proxy renews OAuth files itself, so deployments never overwrite them. Without `secrets.json` the services do not start; start them after provisioning.

## Updates

At 04:00 daily, `cliproxyapi-update` installs the latest checksum-verified release and regenerates the runtime configuration with a refreshed model catalog. The proxy hot-reloads that file, so a catalog change needs no restart; the file is rewritten in place because the proxy watches its inode. The update restarts the backend only when the selected release changed. The proxy closes connections on stop without draining, so that restart interrupts in-flight requests. Failed downloads keep the selected release and fail the unit visibly.

Inspect with `systemctl status cliproxyapi`, `systemctl list-timers cliproxyapi-update`, and `journalctl -u cliproxyapi`.
