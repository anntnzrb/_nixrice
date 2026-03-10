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

    shells.zsh = on;

    desktop.terminal-emulators.ghostty = on;
  };
}
