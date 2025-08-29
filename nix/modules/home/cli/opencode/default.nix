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

  cfg = config.${namespace}.cli.opencode;
in
{
  options.${namespace}.cli.opencode = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.opencode = "bunx --bun opencode-ai@latest";
  };
}
