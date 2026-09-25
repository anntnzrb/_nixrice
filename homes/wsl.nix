{ lib, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ (lib.liberion.fs.getFile "modules/home.nix") ];

  liberion = {
    shells.bash = on;

    suites.common = on;
  };
}
