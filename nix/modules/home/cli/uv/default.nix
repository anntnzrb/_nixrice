{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.uv;
in
{
  options.${namespace}.cli.uv = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.uv = {
      inherit (cfg) enable;
    };
  };
}
