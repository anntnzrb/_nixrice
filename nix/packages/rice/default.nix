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
  runtimeInputs = [ pkgs.rust-script ];
  text = ''
    exec rust-script ${inputs.self + "/bin/rice.rs"} "$@"
  '';
  meta.mainProgram = exe;
}
