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

  cfg = config.${namespace}.programs.vlc;
in
{
  options.${namespace}.programs.vlc = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.homebrew.packages.casks = [ "vlc" ];
  };
}
