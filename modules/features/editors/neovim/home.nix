{
  inputs,
  lib,
  pkgs,
  ...
}:
let

  package =
    inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.default;
  exe = lib.getExe package;
in
{
  home = {
    packages = [ package ];
    sessionVariables = {
      EDITOR = exe;
      VISUAL = exe;
    };
    shellAliases.v = exe;
  };
}
