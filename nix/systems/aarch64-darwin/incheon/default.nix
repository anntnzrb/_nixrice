{ lib
, namespace
, ...
}: {
  # zsh as an interactive shell; this is a force default
  # customization is done via hm
  programs.zsh.enable = true;

  ${namespace} = with lib.${namespace}; {
    darwin = {
      user = {
        name = "annt";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHoPWVoRBmvoWF445a0vTnV2ASk+5Gy/XDTEPPjEDd8/ git"
        ];
      };
    };

    system = {
      trackpad = on;
      ui.menuBar.hide = false;
    };

    services = {
      yabai = off;
    };

    homebrew = {
      enable = true;

      packages = {
        casks = [
          # apps
          "bitwarden"
          "chatgpt"
          "firefox"
          "whatsapp"
          "obs"
          "docker"

          # dev
          "visual-studio-code"
          "rustdesk"
        ];
      };
    };
  };
}
