{ config, lib, ... }:
let
  cfg = config.liberion.network.tailscale;
  tailscale = lib.getExe config.services.tailscale.package;
  mappings = lib.mapAttrsToList (
    name: mapping:
    let
      expose = lib.liberion.tailscaleExpose tailscale name mapping;
    in
    {
      name = "tailscale-expose-${name}";
      value = {
        inherit (expose) description;
        after = [
          "tailscaled.service"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];
        requires = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ (builtins.toJSON mapping) ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = expose.start;
          ExecStop = expose.stop;
          TimeoutStartSec = 60;
          TimeoutStopSec = 30;
          Restart = "on-failure";
          RestartSec = 30;
        };
      };
    }
  ) cfg.expose;
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    # Applied by tailscaled-set on every start; extraUpFlags would need authKeyFile.
    # Serve and Funnel belong to the root-owned tailscale-expose units below;
    # no login user may reconfigure tailscaled without sudo.
    extraSetFlags = [
      "--ssh=false"
      "--hostname=${config.networking.hostName}"
      "--accept-routes=true"
      "--operator="
    ];
  };
  systemd.services = builtins.listToAttrs mappings;
}
