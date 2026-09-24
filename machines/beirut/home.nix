{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ ../../modules/home.nix ];

  ${namespace} = {
    suites.common = on;

    shells.zsh = on;

    desktop = {
      terminal-emulators.ghostty = on;
      whatsapp = on;
    };
  };
}
