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
    shells.bash = on;

    suites = {
      cli = on;
      core = on;
      dev = on;
      llmAgents = on;
    };
  };
}
