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

  programs.zsh.initContent = ''
    source ${lib.liberion.zshInit pkgs "direnv" "HOME=$TMPDIR ${exe} hook zsh"}
  '';
}
