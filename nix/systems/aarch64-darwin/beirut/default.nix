{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  nix.settings = {
    max-jobs = 10;
    cores = 8;
  };

  ${namespace} = {
    suites.desktop = on;

    desktop.window-managers.darwin.yashiki = on;

    system = {
      ui = on // {
        menuBar.hide = false;
      };
    };

    services.tailscale = on;
  };
}
