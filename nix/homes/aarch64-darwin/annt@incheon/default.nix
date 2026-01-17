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

    shells = {
      zsh = on;
    };

    cli = {
      git.gh = on;
      omnix = on;
      yazi = on;
    };

    desktop.terminal-emulators.ghostty = on;
  };
}
