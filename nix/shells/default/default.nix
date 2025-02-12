{
  pkgs,
  inputs,
  system,
  ...
}:
pkgs.mkShellNoCC {
  name = "liberion-shell";

  inherit (inputs.self.checks.${system}.pre-commit-hooks) shellHook;

  nativeBuildInputs = with pkgs; [
    just
    nixd
    nixfmt-rfc-style
  ];
}
