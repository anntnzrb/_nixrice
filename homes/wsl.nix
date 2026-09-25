{ lib, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ ../modules/home.nix ];

  liberion = {
    shells.bash = on;

    suites.common = on;
  };
}
