{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ (lib.${namespace}.fs.getFile "modules/home.nix") ];

  ${namespace} = {
    suites.common = on;

    shells.zsh = on;

    desktop = {
      terminal-emulators.ghostty = on;
    };
  };
}
