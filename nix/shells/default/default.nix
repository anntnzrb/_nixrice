{ pkgs }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    nixpkgs-fmt
    nil
  ];
}
