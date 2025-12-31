/**
  CLI tool for managing Nix flake dotfiles with the rice repository structure.

  # Type

  ```
  rice :: Derivation
  ```
*/
{
  pkgs,
  ...
}:
let
  exe = "rice";
in
pkgs.writers.writePython3Bin exe {
  libraries = [ pkgs.python3Packages.typer ];
  flakeIgnore = [ "E501" ];
} (builtins.readFile ./src/${exe}.py)
