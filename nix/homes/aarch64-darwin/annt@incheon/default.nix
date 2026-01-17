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
    suites.core = on;
    suites.cli = on;
    suites.dev = on;

    shells = {
      zsh = on;
    };

    desktop.terminal-emulators.ghostty = on;
  };
}
