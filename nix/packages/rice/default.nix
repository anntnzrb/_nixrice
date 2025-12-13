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
