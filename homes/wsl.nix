{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ (lib.${namespace}.fs.getFile "modules/home.nix") ];

  ${namespace} = {
    shells.bash = on;

    suites.common = on;
  };
}
