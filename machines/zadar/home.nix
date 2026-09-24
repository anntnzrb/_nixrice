{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ ../../modules/home.nix ];

  ${namespace} = {
    suites.common = on;

    shells.bash = on;
  };
}
