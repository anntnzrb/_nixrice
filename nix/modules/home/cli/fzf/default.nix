{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.fzf;
in
{
  options.${namespace}.cli.fzf = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config =
    with lib;
    mkIf cfg.enable {
      programs.fzf =
        with pkgs;
        let
          catCmd = "${getExe bat} --color=auto -P";
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
        FZF_COMPLETION_TRIGGER = "~~";
      };
    };
}
