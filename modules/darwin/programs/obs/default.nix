{ lib, config, ... }:
lib.liberion.darwin.programs.mkOneCaskProgram { inherit config; } "obs" "obs"
