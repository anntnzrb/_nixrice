{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe getExe';
in
{
  programs.fzf =
    let
      catCmd = getExe' pkgs.coreutils "cat";
      treeCmd = "${getExe pkgs.tree} -C";
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

  programs.zsh.initContent = lib.mkOrder 910 ''
    if [[ $options[zle] = on ]]; then
      source ${
        lib.liberion.zshInit pkgs "fzf"
          "HOME=$TMPDIR ${getExe config.programs.fzf.package} --zsh"
      }
    fi
  '';
}
