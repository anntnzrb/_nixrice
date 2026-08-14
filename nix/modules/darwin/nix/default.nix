{
  lib,
  inputs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) off;

  cfg = config.${namespace}.nix;
in
{
  imports = [
    (lib.${namespace}.fs.getFile "modules/shared/nix/default.nix")
    inputs.determinate.darwinModules.default
  ];

  config = lib.mkIf cfg.enable {
    # Determinate Nix manages /etc/nix/nix.conf, so disable nix-darwin's nix module to avoid conflicts
    nix = off;

    # Custom settings written to /etc/nix/nix.custom.conf
    determinateNix.customSettings = {
      extra-substituters = cfg.substituters;
      trusted-substituters = cfg.substituters;
      extra-trusted-public-keys = cfg.trustedPublicKeys;
      trusted-users = [
        "root"
        "@admin"
      ];
    };

    determinateNix.determinateNixd = {
      # Daemon-side background GC; replaces nix-darwin's nix.gc.*
      # (unusable while the nix module is off for Determinate)
      garbageCollector.strategy = "automatic";
      telemetry.sentry.endpoint = null;
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
