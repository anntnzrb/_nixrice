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

    shells = {
      bash = on;
    };

    cli = {
      yazi = on;
    };
  };
}
