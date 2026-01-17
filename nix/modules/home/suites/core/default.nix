{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.suites.core;
in
{
  options.${namespace}.suites.core = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      shells = {
        sessionVariables.EDITOR = "nvim";
        prompt.starship = on;
        preliminaryMessage.disable = true;
        tmux = on;
      };

      cli = {
        git = on // {
          gh = on;
          lazygit = on;
        };

        btop = on;
        direnv = on;
        fastfetch = on;
        fzf = on;
        tldr = on;
        yt-dlp = on;
        zoxide = on;
      };

      editors.neovim = on;
    };
  };
}
