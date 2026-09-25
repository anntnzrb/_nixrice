{ lib, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ ../../modules/home.nix ];

  liberion = {
    suites.common = on;

    shells.zsh = on;

    desktop = {
      terminal-emulators.ghostty = on;
    };
  };
}
