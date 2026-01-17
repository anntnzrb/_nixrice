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
    suites.llmAgents = on;

    shells = {
      fish = on;
      zsh = on;
    };

    cli = {
      git.gh = on;
      tldr = on;
      yazi = on;
      yt-dlp = on;
    };

    desktop = {
      terminal-emulators.ghostty = on;
      browsers.firefox = on;
    };
  };
}
