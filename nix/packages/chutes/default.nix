{
  pkgs,
  ...
}:
let
  exe = "chutes";
in
pkgs.writeShellApplication {
  name = exe;

  runtimeInputs = with pkgs; [
    curl
    jq
  ];

  text = builtins.readFile ./src/${exe}.sh;
}
