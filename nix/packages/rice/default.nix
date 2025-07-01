{
  pkgs,
  inputs,
  ...
}:
let
  exe = "rice";
in
pkgs.writeShellApplication {
  name = exe;
  text = builtins.readFile (inputs.self + "/bin/rice.sh");
  meta.mainProgram = exe;
}
