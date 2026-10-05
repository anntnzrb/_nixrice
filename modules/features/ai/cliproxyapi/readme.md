# CLIProxyAPI

Import `inputs.self.nixosModules.cliproxyapi` on the Linux gateway host. This is a NixOS system service with a dedicated `cliproxyapi` user and state under `/var/lib/cliproxyapi`; it does not use Home Manager, agents runtime or the owner's home.

Nix generates the public YAML configuration. A small runtime merger supplies private credential pools through systemd credentials and writes the private configuration under `/run/cliproxyapi`. No template substitutions, remote model discovery, System One facade or custom management panel are installed. Use CLIProxyAPI's upstream management behavior.

## Private provisioning

Provision the configured credentials file with mode `0600`, outside Git and the Nix store. It retains `CLIPROXY_CREDENTIAL_POOLS` from the previous deployment and `CLIPROXY_FUNNEL_TOKEN` when public authentication is enabled. Transfer OAuth credential JSON files to the configured auth directory with ownership restricted to the service user. Do not copy old generated configuration, scripts or backups over Nix-owned resources.

Missing credentials prevent startup; adding them does not itself trigger a start. Start the system service after provisioning. The installed release is selected from checksum-verified versioned directories. An absent binary is bootstrapped; an existing binary starts without requiring an upstream network request.

## Releases and exposure

The scheduled release updater checks latest independently of Nix deployments and restarts the backend only when its selected release changes. Updates can interrupt in-flight requests; the backend receives a graceful shutdown window. Failed downloads or checksums preserve the selected release and fail visibly.

The optional public auth gate permits inference paths and rejects management routes. Public and private exposure are configured separately through `liberion.network.tailscale.expose` on the host. Never expose the backend directly through Funnel. Tailscale enrollment and policy grants are prerequisites.

## Migration

Keep Munich serving until credentials are provisioned on Solna and both private and token-authenticated requests pass. Client endpoint changes, removal of agents server-side ownership and shutdown of Munich are separate cutover operations. Provider model aliases formerly synthesized from models.dev are no longer generated; verify clients against the native `/v1/models` catalog before cutover.

Inspect system units with `systemctl status cliproxyapi`, `systemctl list-timers`, and `journalctl -u cliproxyapi`. Tests for public authentication remain beside the module. This module's implementation is self-contained and no secrets are logged by the configuration merger.
