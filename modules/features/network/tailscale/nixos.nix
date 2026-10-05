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
  options.liberion.network.tailscale.expose = lib.mkOption {
    default = { };
    description = "Owned HTTPS Serve/Funnel mappings; requires existing tailnet enrollment and policy grants.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "HTTPS listener port.";
          };
          target = lib.mkOption {
            type = lib.types.strMatching "https?://(127[.]0[.]0[.]1|localhost|[[]::1[]]):[0-9]+(/.*)?";
            description = "Loopback HTTP upstream.";
          };
          funnel = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Publish publicly through Funnel instead of private Serve.";
          };
        };
      }
    );
  };
  config = {
    assertions = [
      {
        assertion =
          lib.length (lib.unique (map (m: m.port) (lib.attrValues cfg.expose)))
          == lib.length (lib.attrValues cfg.expose);
        message = "Tailscale exposure mappings must own distinct HTTPS ports.";
      }
      {
        assertion = lib.all (
          m:
          !m.funnel
          || builtins.elem m.port [
            443
            8443
            10000
          ]
        ) (lib.attrValues cfg.expose);
        message = "Tailscale Funnel supports HTTPS ports 443, 8443 and 10000.";
      }
    ];
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
      extraUpFlags = [
        "--ssh"
        "--hostname=${config.networking.hostName}"
        "--accept-routes=true"
      ];
    };
    systemd.services = builtins.listToAttrs mappings;
  };
}
