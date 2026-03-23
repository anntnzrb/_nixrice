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
      "llm-agents" = on;
    };

    shells.zsh = on;

    desktop = {
      terminal-emulators.ghostty = on;
    };
  };
}
