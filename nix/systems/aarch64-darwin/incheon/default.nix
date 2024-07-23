{ lib
, namespace
, ...
}: {
  # zsh as an interactive shell; this is a force default
  # customization is done via hm
  programs.zsh.enable = true;

  ${namespace} = with lib.${namespace}; {
    darwin = {
      user.name = "annt";
    };

    system = {
      trackpad = on;
      ui.menuBar.hide = false;
    };

    services = {
      yabai = on;
    };

    homebrew = {
      enable = true;

      packages = {
        casks = [
          "firefox"
          "bitwarden"
          "chatgpt"
          "visual-studio-code"
        ];
      };
    };
  };
}
