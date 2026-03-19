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

    shells.zsh = on;
    editors.emacs = on;

    desktop = {
      terminal-emulators.ghostty = on;
      whatsapp = on;
    };
  };
}
