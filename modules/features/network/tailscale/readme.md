# Tailscale exposure

`liberion.network.tailscale.expose` declares independently owned HTTPS Serve or Funnel listeners on NixOS and nix-darwin. Each mapping selects a listener port and a loopback HTTP target; `funnel` publishes the listener publicly. The service only configures Tailscale: it does not start or validate the application behind that target.

Enroll the machine first and grant the required Serve/Funnel capabilities in tailnet policy. Configuration failures are reported by the mapping's systemd unit and retried. The units own individual ports, not the entire Tailscale Serve configuration; stop/removal disables their listeners without resetting unrelated ports. Do not also configure those same ports manually or through the upstream all-config Serve module.

On NixOS no login user is a Tailscale operator: the module clears `OperatorUser` on every boot, so only root, and therefore only these units, can change Serve, Funnel or other tailscaled settings. Applications that offer to publish themselves, such as `t3 pair --tailscale`, are denied; publish them here instead.

Funnel requires application authentication on the upstream. Use it only behind an authenticated endpoint, never directly for a private management listener. Public mappings are intentionally explicit in machine configuration.

On NixOS each mapping is a systemd unit `tailscale-expose-<name>` that retries failures and turns its listener off when stopped. On Darwin it is a launchd daemon of the same name that reruns every 30 seconds until Tailscale accepts the mapping; removing a mapping does not turn its listener off, so run `tailscale serve --https=<port> off` once. Inspect with `tailscale serve status` / `tailscale funnel status`, plus `systemctl status tailscale-expose-<name>` on NixOS or `/var/log/tailscale-expose-<name>.log` on Darwin. Tailnet grants, DNS and enrollment are runtime prerequisites, not supplied by this module.
