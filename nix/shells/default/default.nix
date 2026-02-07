{
  pkgs,
  inputs,
  ...
}:
pkgs.mkShell {
  name = "liberion-shell";

  inherit (inputs.self.checks.${pkgs.stdenv.hostPlatform.system}.pre-commit-hooks)
    shellHook
    ;

  nativeBuildInputs = with pkgs; [
    nixd
    nixfmt
  ];
}
