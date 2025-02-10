{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (lib) getExe;

  cfg = config.${namespace}.cli.fzf;
in
{
  options.${namespace}.cli.fzf = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.fzf =
      let
        catCmd = "${getExe pkgs.bat} --color=auto -P";
        treeCmd = "${getExe pkgs.eza} --color=automatic --icons -T";
      in
      rec {
        enable = true;

        defaultCommand = "${getExe pkgs.fd} --type f";

        # CTL-R
        historyWidgetOptions = [
          "--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
        ];

        # CTL-T
        fileWidgetCommand = defaultCommand;
        fileWidgetOptions = [ "--preview '${catCmd} {} 2>/dev/null || ${treeCmd} {}'" ];

        # ALT-C
        changeDirWidgetCommand = "${getExe pkgs.fd} --type d";
        changeDirWidgetOptions = [ "--preview '${treeCmd} {}'" ];
      };

    # NOTE: this might be a future module option
    home.sessionVariables = {
      FZF_COMPLETION_TRIGGER = "~~";
    };
  };
}
