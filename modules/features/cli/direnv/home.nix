{
  config,
  lib,
  pkgs,
  ...
}:
let

  exe = lib.getExe config.programs.direnv.package;
in
{
  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
    enableZshIntegration = false;
  };

  home.shellAliases.dirrr = "${exe} allow && ${exe} reload";

  programs.zsh.initContent =
    let
      zshInit = pkgs.runCommand "direnv-zsh-init" { } ''
        HOME=$TMPDIR ${lib.getExe config.programs.direnv.package} hook zsh > $out
      '';
    in
    ''
      source ${zshInit}
    '';
}
