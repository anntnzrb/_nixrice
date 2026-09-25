{ lib, config, ... }:
# OrbStack updates itself and installs a privileged helper, so it lives in
# /Applications as a cask rather than in the read-only Nix store.
lib.liberion.darwin.programs.mkOneCaskProgram {
  inherit config;
} "orbstack" "orbstack"
