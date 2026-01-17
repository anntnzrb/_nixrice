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
      claude-code = on;
      codex = on;
      crush = on;
      droid = on;
      gemini = on;
      goose = on;
      kilo = on;
      opencode = on;
      pi = on;
      qwen = on;
    };
  };
}
