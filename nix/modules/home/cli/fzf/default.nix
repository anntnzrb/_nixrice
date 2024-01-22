{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.cli.fzf;
in
{
  options.liberion.cli.fzf = {
    enable = lib.mkEnableOption "fzf";
  };

  config = lib.mkIf cfg.enable {
    programs.fzf =
      let
        catCmd = "bat --color=auto -P";
        treeCmd = "eza --color=automatic --icons -FT";
      in
      rec {
        enable = true;

        defaultCommand = "fd --type f";

        # CTL-R
        historyWidgetOptions = [ "--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'" ];

        # CTL-T
        fileWidgetCommand = defaultCommand;
        fileWidgetOptions = [ "--preview '${catCmd} {} 2>/dev/null || ${treeCmd} {}'" ];

        # ALT-C
        changeDirWidgetCommand = "fd --type d";
        changeDirWidgetOptions = [ "--preview '${treeCmd} {}'" ];
      };

    home = {
      packages = with pkgs; [
        fd
        eza
      ];

      # NOTE: this might be a future module option
      sessionVariables = {
        FZF_COMPLETION_TRIGGER = ".";
      };
    };
  };
}
