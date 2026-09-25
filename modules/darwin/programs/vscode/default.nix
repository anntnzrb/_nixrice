{ lib, config, ... }:
lib.liberion.darwin.programs.mkOneCaskProgram {
  inherit config;
} "vscode" "visual-studio-code"
