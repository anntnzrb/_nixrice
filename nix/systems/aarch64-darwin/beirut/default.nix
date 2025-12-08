{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  # zsh as an interactive shell; this is a forced default
  # customization is done via hm
  programs.zsh = on;

  nix.settings = {
    max-jobs = 10;
    cores = 8;
  };

  ${namespace} = {
    system = {
      keyboard = on;
      dock = on;
      finder = on;
      trackpad = on;

      ui = on // {
        menuBar.hide = false;
      };
    };

    services.aerospace = on;

    network.ssh = on;

    homebrew = on // {
      packages = {
        casks = [
          "aldente"
          "orbstack"
          "rustdesk"
        ];
        masApps = {
          "WhatsApp Messenger" = 310633997;
          "Bitwarden" = 1352778147;
        };
      };
    };
  };
}
