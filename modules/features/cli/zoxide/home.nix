{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfgOptions = lib.concatStringsSep " " config.programs.zoxide.options;
  zshInit =
    lib.liberion.zshInit pkgs "zoxide"
      "HOME=$TMPDIR ${lib.getExe config.programs.zoxide.package} init zsh ${cfgOptions}";
in
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;
  };

  programs.zsh.initContent = lib.mkOrder 851 ''
    source ${zshInit}
  '';
}
