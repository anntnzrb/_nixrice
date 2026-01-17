{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  ${namespace} = {
    suites.core = on;
    suites.cli = on;
    suites.dev = on;
    suites.llmAgents = on;

    shells = {
      bash = on;
    };

    cli = {
      git.gh = on;
    };
  };
}
