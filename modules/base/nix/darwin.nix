# Remote builders: modules/services/remote-builders (clan service, clan.nix).
{
  lib,
  inputs,
  config,
  ...
}:
let
  cfg = config.liberion.nix;
in
{
  imports = [ inputs.determinate.darwinModules.default ];

  config = {
    # Determinate Nix manages /etc/nix/nix.conf, so disable nix-darwin's nix module to avoid conflicts
    nix.enable = false;

    determinateNix = {
      # Custom settings written to /etc/nix/nix.custom.conf
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
        # Daemon-side background GC; replaces nix-darwin's nix.gc.*
        # (unusable while the nix module is off for Determinate)
        garbageCollector.strategy = "automatic";
        telemetry.sentry.endpoint = null;
      };
    };

    # macOS sudoers keeps HOME by default, letting root-run tools pollute the
    # user's home (~/.cache and friends); drop it so root gets /var/root.
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
