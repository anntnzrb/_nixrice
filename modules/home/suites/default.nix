{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.suites;
in
{
  options.${namespace}.suites = {
    cli.enable = mkOptDisabled';
    common.enable = mkOptDisabled';
    core.enable = mkOptDisabled';
    desktop.enable = mkOptDisabled';
    dev.enable = mkOptDisabled';
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.cli.enable {
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
          janet = on;
          fzf = on;
          tldr = on;
          yazi = on;
          yt-dlp = on;
          zoxide = on;
        };

        editors.neovim = on;
      };
    })

    (lib.mkIf cfg.common.enable {
      ${namespace}.suites = {
        cli = on;
        core = on;
        dev = on;
      };
    })

    (lib.mkIf cfg.core.enable {
      ${namespace}.shells = {
        prompt.starship = on;
        preliminaryMessage.disable = true;
      };
    })

    (lib.mkIf cfg.desktop.enable { ${namespace}.desktop.ui.themes = on; })

    (lib.mkIf cfg.dev.enable {
      ${namespace}.cli = {
        omnix = on;
        husky = on;
        node = on;
        repomix = on;
        bun = on;
        uv = on;
      };
    })
  ];
}
