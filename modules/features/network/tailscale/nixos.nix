{ config, lib, ... }:
let
  cfg = config.liberion.network.tailscale;
  tailscale = lib.getExe config.services.tailscale.package;
  mappings = lib.mapAttrsToList (name: mapping: {
    name = "tailscale-expose-${name}";
    value = {
      description = "Tailscale ${
        if mapping.funnel then "Funnel" else "Serve"
      } mapping ${name}";
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
        ExecStart = "${tailscale} ${
          if mapping.funnel then "funnel" else "serve"
        } --bg --https=${toString mapping.port} ${mapping.target}";
        ExecStop = "${tailscale} ${
          if mapping.funnel then "funnel" else "serve"
        } --https=${toString mapping.port} off";
        TimeoutStartSec = 60;
        TimeoutStopSec = 30;
        Restart = "on-failure";
        RestartSec = 30;
      };
    };
  }) cfg.expose;
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--ssh"
      "--hostname=${config.networking.hostName}"
      "--accept-routes=true"
    ];
    # Serve and Funnel belong to the root-owned tailscale-expose units below;
    # no login user may reconfigure tailscaled without sudo.
    extraSetFlags = [ "--operator=" ];
  };
  systemd.services = builtins.listToAttrs mappings;
}
