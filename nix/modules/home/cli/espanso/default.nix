{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.espanso;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./matches;

  options.${namespace}.cli.espanso = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.espanso = {
      inherit (cfg) enable;
    };
  };
}
