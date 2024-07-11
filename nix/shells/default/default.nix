{ pkgs
, ...
}:
pkgs.mkShell {
  name = "liberion-shell";

  nativeBuildInputs = with pkgs; [
    just
  ];
}
