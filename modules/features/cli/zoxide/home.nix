{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfgOptions = lib.concatStringsSep " " config.programs.zoxide.options;
  init =
    lib.liberion.zshInit pkgs "zoxide"
      "${lib.getExe config.programs.zoxide.package} init zsh ${cfgOptions}";
in
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;
  };

  programs.zsh.initContent = lib.mkOrder 851 ''
    source ${init}
  '';
}
