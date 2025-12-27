{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  mkAgent = import ../lib.nix {
    inherit
      lib
      namespace
      pkgs
      config
      ;
  };

in
mkAgent {
  name = "codex";
  attr = "codex";
}
