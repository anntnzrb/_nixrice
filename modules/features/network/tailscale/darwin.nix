{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.liberion.network.tailscale;
  routeGuard = pkgs.writeShellApplication {
    name = "tailscale-route-guard";
    runtimeInputs = [ pkgs.gawk ];
    text = builtins.readFile ./route-guard.sh;
  };
  reconcile = pkgs.writeShellApplication {
    name = "tailscale-expose-reconcile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      config.services.tailscale.package
    ];
    text = builtins.readFile ./reconcile.sh;
  };
  manifest = pkgs.writeText "tailscale-expose-owned.json" (
    builtins.toJSON (
      lib.mapAttrsToList (name: mapping: {
        inherit (mapping) port;
        stop =
          lib.splitString " "
            (lib.liberion.tailscaleExpose "tailscale" name mapping).stop;
      }) cfg.expose
    )
  );
  tailscale = lib.getExe config.services.tailscale.package;
  mappings = lib.mapAttrs' (
    name: mapping:
    lib.nameValuePair "tailscale-expose-${name}" {
      command = (lib.liberion.tailscaleExpose tailscale name mapping).start;
      # Rerun until tailscaled accepts the mapping, then stay done.
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
        ThrottleInterval = 30;
        StandardErrorPath = "/var/log/tailscale-expose-${name}.log";
      };
    }
  ) cfg.expose;
in
{
  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };
  environment.etc."resolver/ts.net".enable = lib.mkForce false;

  liberion.darwin.owned.files."/var/lib/liberion/tailscale-expose.json" = { };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    ${lib.getExe reconcile} /var/lib/liberion/tailscale-expose.json ${manifest} \
      || echo >&2 "tailscale: failed to reconcile listeners; keeping ownership to retry on the next switch"
  '';

  launchd.daemons = mappings // {
    tailscaled.serviceConfig.KeepAlive = true;
    "tailscale-route-guard" = {
      command = lib.getExe routeGuard;
      serviceConfig = {
        RunAtLoad = true;
        StartInterval = 30;
      };
    };
  };
}
