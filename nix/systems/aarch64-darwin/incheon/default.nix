{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  nix.settings = {
    max-jobs = 8;
    cores = 4;
  };

  ${namespace} = {
    suites.desktop = on;

    system = {
      ui = on // {
        menuBar.hide = true;
      };
    };

    programs = {
      obs = on;
      rustdesk = on;
      vlc = on;
      vscode = on;
    };
  };
}
