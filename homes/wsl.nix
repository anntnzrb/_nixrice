{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ ../modules/home.nix ];

  ${namespace} = {
    shells.bash = on;

    suites.common = on;
  };
}
