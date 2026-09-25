import ../../../toggle.nix "cli.fzf" (
  { lib, pkgs, ... }:
  let
    inherit (lib) getExe;
  in
  {
    programs.fzf =
      let
        catCmd = "${getExe pkgs.bat} --color=auto -P";
        treeCmd = "${getExe pkgs.eza} --color=automatic --icons -T";
        defaultCommand = "${getExe pkgs.fd} --type f";
      in
      {
        enable = true;
        inherit defaultCommand;

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
  }
)
