{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.cli.zoxide;
in
{
  options.${namespace}.cli.zoxide = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.zoxide.enable = true;
  };
}
