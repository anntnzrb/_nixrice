{ lib, config, ... }:
lib.liberion.darwin.programs.mkOneMasAppProgram {
  inherit config;
} "bitwarden" "Bitwarden" 1352778147
