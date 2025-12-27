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
    (lib.snowfall.fs.get-file "modules/shared/nix/default.nix")
    inputs.determinate.darwinModules.default
  ];

  config = lib.mkIf cfg.enable {
    # Determinate Nix manages /etc/nix/nix.conf, so disable nix-darwin's nix module to avoid conflicts
    nix = off;

    # Custom settings written to /etc/nix/nix.custom.conf
    determinate-nix.customSettings = {
      extra-substituters = cfg.substituters;
      trusted-substituters = cfg.substituters;
      extra-trusted-public-keys = cfg.trustedPublicKeys;
      trusted-users = [
        "root"
        "@admin"
      ];
    };

    system.activationScripts.postActivation.text = ''
      if launchctl print system/systems.determinate.nix-daemon >/dev/null 2>&1; then
        launchctl kickstart -k system/systems.determinate.nix-daemon
      fi
    '';
  };
}
