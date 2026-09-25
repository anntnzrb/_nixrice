import ../../../toggle.nix "cli.rust" (
  { pkgs, inputs, ... }: {
    home.packages = [
      (
        inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents
          [
            "cargo"
            "rustc"
            "clippy"
            "rustfmt"
          ]
      )
    ];
  }
)
