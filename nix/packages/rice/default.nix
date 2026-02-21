/**
  CLI tool for managing Nix flake dotfiles with the rice repository structure.

  # Type

  ```
  rice :: Derivation
  ```
*/
{
  pkgs,
  ...
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "rice";
  version = "0.1.0";
  src = ./src;
  cargoLock.lockFile = ./src/Cargo.lock;
}
