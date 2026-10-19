# Tailscale exposure

- Grant Serve and Funnel in tailnet policy first; enrollment and grants are not managed here.
- Never configure an owned port by hand or through the upstream Serve module.
- Funnel only an endpoint that authenticates, never a management listener.
- Before removing the Darwin import, clear its mappings and activate once, or the listeners stay up.
