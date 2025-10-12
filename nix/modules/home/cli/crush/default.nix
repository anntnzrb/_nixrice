{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOptDisabled'
    ;

  cfg = config.${namespace}.cli.crush;
in
{
  options.${namespace}.cli.crush = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.crush = "bun x @charmland/crush -- --yolo";
  };
}
