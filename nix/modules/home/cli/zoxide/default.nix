{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.cli.zoxide;
in
{
  options.${namespace}.cli.zoxide = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config =
    with lib;
    mkIf cfg.enable {
      programs.zoxide = {
        enable = true;
      };
    };
}
