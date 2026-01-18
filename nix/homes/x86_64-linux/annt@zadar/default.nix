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
    suites = {
      cli = on;
      core = on;
      dev = on;
      llmAgents = on;
    };

    shells.bash = on;

    cli.clawdbot = on;
  };
}
