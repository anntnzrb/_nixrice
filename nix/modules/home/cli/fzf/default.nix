{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.liberion.cli.fzf;
in
{
  options.liberion.cli.fzf = with lib.liberion; {
    enable = mkOptBool';
  };

  config =
    with lib;
    mkIf cfg.enable {
      programs.fzf =
        with pkgs;
        let
          catCmd = "${getExe bar} --color=auto -P";
          treeCmd = "${getExe eza} --color=automatic --icons -T";
        in
        rec {
          enable = true;

          defaultCommand = "${getExe fd} --type f";

          # CTL-R
          historyWidgetOptions = [
            "--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
          ];

          # CTL-T
          fileWidgetCommand = defaultCommand;
          fileWidgetOptions = [ "--preview '${catCmd} {} 2>/dev/null || ${treeCmd} {}'" ];

          # ALT-C
          changeDirWidgetCommand = "${getExe fd} --type d";
          changeDirWidgetOptions = [ "--preview '${treeCmd} {}'" ];
        };

      # NOTE: this might be a future module option
      home.sessionVariables = {
        FZF_COMPLETION_TRIGGER = ".";
      };
    };
}
