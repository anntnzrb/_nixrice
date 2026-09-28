{
  config,
  lib,
  pkgs,
  ...
}:
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
      enableZshIntegration = false;

      historyWidgetOptions = [
        "--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
      ];

      fileWidgetCommand = defaultCommand;
      fileWidgetOptions = [ "--preview '${catCmd} {} 2>/dev/null || ${treeCmd} {}'" ];

      changeDirWidgetCommand = "${getExe pkgs.fd} --type d";
      changeDirWidgetOptions = [ "--preview '${treeCmd} {}'" ];
    };

  home.sessionVariables = {
    FZF_COMPLETION_TRIGGER = "~~";
  };

  programs.zsh.initContent =
    let
      zshInit = pkgs.runCommand "fzf-zsh-init" { } ''
        HOME=$TMPDIR ${lib.getExe config.programs.fzf.package} --zsh > $out
      '';
    in
    lib.mkOrder 910 ''
      if [[ $options[zle] = on ]]; then
        source ${zshInit}
      fi
    '';
}
