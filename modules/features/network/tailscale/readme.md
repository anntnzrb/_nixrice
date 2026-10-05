# Tailscale exposure

`liberion.network.tailscale.expose` declares independently owned HTTPS Serve or Funnel listeners on NixOS. Each mapping selects a listener port and a loopback HTTP target; `funnel` publishes the listener publicly. The service only configures Tailscale: it does not start or validate the application behind that target.

Enroll the machine first and grant the required Serve/Funnel capabilities in tailnet policy. Configuration failures are reported by the mapping's systemd unit and retried. The units own individual ports, not the entire Tailscale Serve configuration; stop/removal disables their listeners without resetting unrelated ports. Do not also configure those same ports manually or through the upstream all-config Serve module.

Funnel requires application authentication on the upstream. Use it only behind an authenticated endpoint, never directly for a private management listener. Public mappings are intentionally explicit in machine configuration.

Inspect `systemctl status tailscale-expose-<name>` and `tailscale serve status` / `tailscale funnel status`. Tailnet grants, DNS and enrollment are runtime prerequisites, not supplied by this module.
