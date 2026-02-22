/**
  CLI tool for managing Nix flake dotfiles with the rice repository structure.

  # Type

  ```
  rice :: Derivation
  ```
*/
{
  pkgs,
  inputs,
  ...
}:
let
  cargoToml = builtins.fromTOML (builtins.readFile ./src/Cargo.toml);
  inherit (cargoToml) package;
  pname = package.name;
  inherit (package) version;

  toolchain =
    inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents
      [
        "cargo"
        "rustc"
        "clippy"
        "rustfmt"
      ];

  rustPlatform = pkgs.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
in
rustPlatform.buildRustPackage {
  inherit pname version;
  src = ./src;
  cargoLock.lockFile = ./src/Cargo.lock;

  postCheck = ''
    cargo fmt --all --check
    cargo clippy --all-targets --all-features --offline --frozen -- -D warnings
    cargo doc --no-deps --offline --frozen
  '';
}
