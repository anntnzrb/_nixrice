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
  runtimeInputs = [ pkgs.uv ];
  text = ''
    exec uv run ${inputs.self + "/bin/rice.py"} "$@"
  '';
  meta.mainProgram = exe;
}
