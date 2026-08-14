{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  determinateNix.customSettings = {
    # nix-darwin's nix module is disabled on darwin
    # (Determinate Nix owns nix.conf)
    # so these must go through the determinate module to be live.
    max-jobs = 10;
    cores = 8;
  };

  ${namespace} = {
    suites.desktop = on;

    desktop.window-managers.darwin.aerospace = on;

    system = {
      ui = on // {
        menuBar.hide = false;
      };
    };

  };
}
