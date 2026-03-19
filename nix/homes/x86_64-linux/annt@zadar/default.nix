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
      dev = on;
      llmAgents = on;
    };

    shells.bash = on;
  };
}
