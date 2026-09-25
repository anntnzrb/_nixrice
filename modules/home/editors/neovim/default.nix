import ../../../toggle.nix "editors.neovim" (
  {
    lib,
    pkgs,
    inputs,
    ...
  }:
  let

    package = inputs.neovim-annt.packages.${pkgs.stdenv.hostPlatform.system}.nixvim;
  in
  {
    home = {
      packages = [ package ];
      shellAliases.v = lib.getExe package;
    };
  }
)
