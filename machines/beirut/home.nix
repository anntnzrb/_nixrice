{ lib, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ (lib.liberion.fs.getFile "modules/home.nix") ];

  liberion = {
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
