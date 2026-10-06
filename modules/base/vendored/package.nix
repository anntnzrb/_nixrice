{ pkgs }:
pkgs.writeShellApplication {
  name = "vendored-update";
  runtimeInputs = with pkgs; [
    coreutils
    findutils
    flock
    git
    openssh
  ];
  text = builtins.readFile ./update.sh;
}
