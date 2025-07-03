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

  cfg = config.${namespace}.cli.claude;
in
{
  options.${namespace}.cli.claude = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.sessionPath = [ "${config.home.homeDirectory}/.claude/bin" ];
  };
}
