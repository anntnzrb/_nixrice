{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  ${namespace} = {
    suites.common = on;

    shells.zsh = on;

    services.t3 = on;

    desktop = {
      browsers.brave = on;
      terminal-emulators.ghostty = on;
      whatsapp = on;
    };
  };
}
