{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.shells.fish;
in
{
  options.liberion.shells.fish = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      inherit (cfg) enable;
      interactiveShellInit = ''
        set -g fish_greeting # disable greeting
      '';
    };
  };
}
