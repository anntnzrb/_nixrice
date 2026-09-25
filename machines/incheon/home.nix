{ lib, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ (lib.liberion.fs.getFile "modules/home.nix") ];

  liberion = {
    suites.common = on;

    shells.zsh = on;

    desktop = {
      terminal-emulators.ghostty = on;
    };
  };
}
