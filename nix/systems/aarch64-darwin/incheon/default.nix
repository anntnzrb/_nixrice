{ lib
, namespace
, ...
}: {
  # zsh as an interactive shell; this is a force default
  # customization is done via hm
  programs.zsh.enable = true;

  ${namespace} = with lib.${namespace}; {
    darwin = {
      system = {
        trackpad = on;
      };

      services = {
        yabai = on;
      };

      homebrew = on;
    };
  };
}
