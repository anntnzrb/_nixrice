{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.suites.cli;
in
{
  options.${namespace}.suites.cli = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      shells = {
        sessionVariables.EDITOR = "nvim";
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
        yazi = on;
        yt-dlp = on;
        zoxide = on;
      };

      editors.neovim = on;
    };
  };
}
