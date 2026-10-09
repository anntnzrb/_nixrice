{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.liberion.nix;
in
{
  imports = [ inputs.determinate.darwinModules.default ];

  config = {
    nix.enable = false;

    determinateNix = {
      customSettings = {
        extra-substituters = lib.attrNames cfg.caches;
        trusted-substituters = lib.attrNames cfg.caches;
        extra-trusted-public-keys = lib.attrValues cfg.caches;
        trusted-users = [
          "root"
          "@admin"
        ];
      };

      determinateNixd = {
        garbageCollector.strategy = "automatic";
        telemetry.sentry.endpoint = null;
      };
    };

    security.sudo.extraConfig = ''
      Defaults env_keep -= "HOME"
    '';

    system.activationScripts.postActivation.text = ''
      if launchctl print system/systems.determinate.nix-daemon >/dev/null 2>&1; then
        launchctl kickstart -k system/systems.determinate.nix-daemon
      fi
    '';
  };
}
