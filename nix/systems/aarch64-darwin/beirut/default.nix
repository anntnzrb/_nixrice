{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on off;
in
{
  nix.settings = {
    max-jobs = 10;
    cores = 8;
  };

  ${namespace} = {
    suites.desktop = on;

    desktop.window-managers.darwin.aerospace = off;

    system = {
      ui = on // {
        menuBar.hide = false;
      };
    };

    services.tailscale = on;
  };
}
