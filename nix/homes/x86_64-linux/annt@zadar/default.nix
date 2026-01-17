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
      fastfetch = on;
      simple-mtpfs = on;
    };
  };
}
