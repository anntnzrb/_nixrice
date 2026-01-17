{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  ${namespace} = {
    suites.core = on;
    suites.llmAgents = on;

    shells = {
      bash = on;
    };

    cli = {
      git.gh = on;
      husky = on;
      repomix = on;
    };
  };
}
