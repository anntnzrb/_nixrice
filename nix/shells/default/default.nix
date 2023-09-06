{pkgs}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    alejandra
    nixd
  ];
}
