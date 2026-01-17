{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  liberion = {
    suites.core = on;
    suites.cli = on;

    shells = {
      bash = on;
    };

    cli = {
    };
  };
}
