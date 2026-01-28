{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  ${namespace} = {
    suites = {
      cli = on;
      core = on;
    };

    shells = {
      bash = on;
      prompt.starship = on;
    };
  };
}
