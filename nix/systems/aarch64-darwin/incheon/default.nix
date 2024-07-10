{ lib
, namespace
, ...
}: {
  # zsh as an interactive shell; this is a force default
  # customization is done via hm
  programs.zsh.enable = true;

  ${namespace} = with lib.${namespace}; {
    system = {
      trackpad = on;
    };

    services = {
      yabai = on;
    };

    homebrew = {
      enable = true;

      packages = {
        casks = [
          "alacritty"
          "bitwarden"
          "chatgpt"
          "firefox"
          "notesnook"

          # dev
          "visual-studio-code"

          # misc
          "whatsapp"

          # system
          "aldente"
        ];
      };
    };
  };
}
