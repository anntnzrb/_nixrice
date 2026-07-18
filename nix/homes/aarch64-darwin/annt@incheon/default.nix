{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  ${namespace} = {
    suites.common = on;

    shells.zsh = on;

    desktop = {
      terminal-emulators.ghostty = on;
    };
  };
}
