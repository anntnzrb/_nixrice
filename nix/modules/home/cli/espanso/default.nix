{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.cli.espanso;
in
{
  imports = [
    ./matches/personal.nix
    ./matches/dictionary.nix
  ];

  options.${namespace}.cli.espanso = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.espanso.enable = true;
  };
}
