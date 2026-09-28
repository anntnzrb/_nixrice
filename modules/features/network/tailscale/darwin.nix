{ lib, pkgs, ... }:
let

  routeGuard = pkgs.writeShellScript "tailscale-route-guard" ''
    set -eu

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
  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };
  launchd.daemons.tailscaled.serviceConfig.KeepAlive = true;
  environment.etc."resolver/ts.net".enable = lib.mkForce false;

  launchd.daemons."tailscale-route-guard" = {
    command = "${routeGuard}";
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 30;
    };
  };
}
