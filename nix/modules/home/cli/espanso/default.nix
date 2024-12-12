{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.espanso;
in
{
  imports = [
    ./matches/personal.nix
    ./matches/dictionary.nix
  ];

  options.${namespace}.cli.espanso = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.espanso.enable = true;
  };
}
