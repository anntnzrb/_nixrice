{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ ../../modules/home.nix ];

  ${namespace} = {
    suites.common = on;

    shells.zsh = on;

    cli.ssh = on // {
      identityFile = "~/.ssh/beirut";
      includes = [ "~/.orbstack/ssh/config" ];
    };

    desktop = {
      terminal-emulators.ghostty = on;
      whatsapp = on;
    };
  };
}
