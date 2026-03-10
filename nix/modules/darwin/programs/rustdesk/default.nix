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

  cfg = config.${namespace}.programs.rustdesk;
in
{
  options.${namespace}.programs.rustdesk = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.homebrew.packages.casks = [ "rustdesk" ];
  };
}
