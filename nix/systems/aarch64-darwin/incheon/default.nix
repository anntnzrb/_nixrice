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
  programs.zsh.enable = true;

  nix.settings = {
    max-jobs = 8;
    cores = 4;
  };

  ${namespace} = {
    system = {
      trackpad = on;
      ui.menuBar.hide = false;
    };

    services = {
      aerospace = on;
    };

    network.ssh = on;

    homebrew = {
      enable = true;

      packages = {
        casks = [
          "bitwarden"
          "visual-studio-code"
          "docker"
          "ghostty"
          "obs"
          "rustdesk"
          "vlc"
          "whatsapp"
        ];
      };
    };
  };
}
