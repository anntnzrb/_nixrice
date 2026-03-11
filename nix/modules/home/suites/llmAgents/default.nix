{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.suites.llmAgents;
in
{
  options.${namespace}.suites.llmAgents = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.cli.llmAgents = {
      chutes = on;
      claude = on;
      codex = on;
      crush = on;
      droid = on;
      gemini = on;
      goose = on;
      kilo = on;
      opencode = on;
      omp = on;
      pi = on;
      qwen = on;
    };
  };
}
