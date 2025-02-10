{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.zoxide;
in
{
  options.${namespace}.cli.zoxide = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.zoxide.enable = true;
  };
}
