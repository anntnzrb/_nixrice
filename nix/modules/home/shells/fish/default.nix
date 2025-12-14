{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.shells.fish;
in
{
  options.${namespace}.shells.fish = {
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
