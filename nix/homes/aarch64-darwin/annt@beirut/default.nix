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
    editors.emacs = on;

    desktop = {
      browsers.brave = on;
      terminal-emulators.ghostty = on;
      whatsapp = on;
    };
  };
}
