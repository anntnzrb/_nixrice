{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.suites;
in
{
  options.liberion.suites = {
    cli.enable = mkOptDisabled';
    common.enable = mkOptDisabled';
    core.enable = mkOptDisabled';
    desktop.enable = mkOptDisabled';
    dev.enable = mkOptDisabled';
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.cli.enable {
      liberion = {
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
      liberion.suites = {
        cli = on;
        core = on;
        dev = on;
      };
    })

    (lib.mkIf cfg.core.enable {
      liberion.shells = {
        prompt.starship = on;
        preliminaryMessage.disable = true;
      };
    })

    (lib.mkIf cfg.desktop.enable { liberion.desktop.ui.themes = on; })

    (lib.mkIf cfg.dev.enable {
      liberion.cli = {
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
