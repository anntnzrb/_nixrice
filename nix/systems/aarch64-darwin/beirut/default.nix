{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on off;
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

    programs = {
      bitwarden = on;
      orbstack = on;
      whatsapp = on;
    };

    desktop.window-managers.darwin.aerospace = on;
    services.tailscale = off;

    network.ssh = on;

    homebrew = on;
  };
}
