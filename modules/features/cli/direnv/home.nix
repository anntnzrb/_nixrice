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
    config.global = {
      load_dotenv = true;
      strict_env = true;
      hide_env_diff = true;
    };
  };

  home.shellAliases.dirrr = "${exe} allow && ${exe} reload";

  programs.zsh.initContent = ''
    source ${lib.liberion.zshInit pkgs "direnv" "${exe} hook zsh"}
  '';
}
