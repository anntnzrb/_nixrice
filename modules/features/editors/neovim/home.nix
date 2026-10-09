{
  inputs,
  lib,
  pkgs,
  ...
}:
let

  package =
    inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home = {
    packages = [ package ];
    shellAliases.v = lib.getExe package;
  };
}
