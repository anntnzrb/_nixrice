{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  ${namespace} = {
    suites.common = on;

    shells.bash = on;
  };
}
