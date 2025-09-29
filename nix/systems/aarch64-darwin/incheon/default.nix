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
    max-jobs = 8;
    cores = 4;
  };

  ${namespace} = {
    system = {
      keyboard = on;
      dock = on;
      finder = on;
      trackpad = on;

      ui = on // {
        menuBar.hide = true;
      };
    };

    services = {
      aerospace = on;
    };

    network.ssh = on;

    homebrew = on // {
      packages = {
        casks = [
          "bitwarden"
          "visual-studio-code"
          "docker"
          "obs"
          "rustdesk"
          "vlc"
          "whatsapp"
        ];
      };
    };
  };
}
