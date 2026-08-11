{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.suites."llm-agents";
in
{
  options.${namespace}.suites."llm-agents" = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.cli."llm-agents" = {
      codex = on;
      opencode = on;
      omp = on;
      pi = on;
    };
  };
}
