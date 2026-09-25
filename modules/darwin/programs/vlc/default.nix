{ lib, config, ... }:
lib.liberion.darwin.programs.mkOneCaskProgram { inherit config; } "vlc" "vlc"
