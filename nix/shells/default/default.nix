{ pkgs
, ...
}:
pkgs.mkShellNoCC {
  name = "liberion-shell";

  nativeBuildInputs = with pkgs; [
    just
  ];
}
