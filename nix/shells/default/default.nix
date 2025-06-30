{
  pkgs,
  inputs,
  ...
}:
pkgs.mkShellNoCC {
  name = "liberion-shell";

  inherit (inputs.self.checks.${pkgs.system}.pre-commit-hooks) shellHook;

  nativeBuildInputs = with pkgs; [
    nixd
    nixfmt-rfc-style
  ];
}
