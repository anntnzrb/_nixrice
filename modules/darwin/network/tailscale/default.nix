{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.network.tailscale;

  # tailscaled's Darwin userspace router (wgengine/router/osrouter) installs
  # the tailnet routes with route(8) and only tracks them in process memory.
  # If the kernel route table drops the route (observed after sleep/wake on
  # macOS 26), the daemon does not notice and never reinstalls it, so tailnet
  # IPv4 traffic follows the LAN default route and blackholes. Restore the
  # coarse 100.64.0.0/10 route whenever it goes missing.
  routeGuard = pkgs.writeShellScript "tailscale-route-guard" ''
    set -eu

    # The Tailscale utun carries both a CGNAT IPv4 address and the Tailscale
    # ULA prefix. Any other CGNAT interface (a second VPN, or a CGNAT-addressed
    # LAN) makes tailscaled fall back to per-peer /32 routes, in which case its
    # route set is left alone.
    ts_iface=""
    other_cgnat=0
    for iface in $(/sbin/ifconfig -l); do
      addrs="$(/sbin/ifconfig "$iface" 2>/dev/null || true)"
      case "$addrs" in
        *"inet 100."*) ;;
        *) continue ;;
      esac
      case "$addrs" in
        *"inet6 fd7a:115c:a1e0"*) ts_iface="$iface" ;;
        *) other_cgnat=1 ;;
      esac
    done
    [ -n "$ts_iface" ] || exit 0
    [ "$other_cgnat" -eq 0 ] || exit 0

    if /usr/sbin/netstat -rn -f inet | /usr/bin/awk '$1 == "100.64/10" { seen = 1 } END { exit !seen }'; then
      exit 0
    fi
    /sbin/route -q -n add -inet 100.64.0.0/10 -iface "$ts_iface"
  '';
in
{
  options.liberion.network.tailscale = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    # open-source tailscaled (no GUI); state lives in /Library/Tailscale
    services.tailscale = {
      enable = true;
      # track upstream; the stable channel lags the daemon beirut already ran
      package = pkgs.unstable.tailscale;
    };
    launchd.daemons.tailscaled.serviceConfig.KeepAlive = true;
    # tailscaled writes /etc/resolver/ts.net itself (MagicDNS, IPv4 + IPv6)
    # and cannot write through nix-darwin's /etc/static symlink
    environment.etc."resolver/ts.net".enable = lib.mkForce false;

    launchd.daemons."tailscale-route-guard" = {
      # The `command` option wraps ProgramArguments in
      # `/bin/wait4path /nix/store`, without which launchd fails to exec a
      # store path when it starts daemons before the store is mounted.
      command = "${routeGuard}";
      serviceConfig = {
        RunAtLoad = true;
        StartInterval = 30;
      };
    };
  };
}
