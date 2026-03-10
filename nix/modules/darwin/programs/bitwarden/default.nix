{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptDisabled'
    ;
  inherit (lib.types)
    ints
    str
    ;

  cfg = config.${namespace}.programs.bitwarden;
in
{
  options.${namespace}.programs.bitwarden = {
    enable = mkOptDisabled';
    masAppName = mkOpt' str "Bitwarden";
    masAppId = mkOpt' ints.positive 1352778147;
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.homebrew.packages.masApps = {
      "${cfg.masAppName}" = cfg.masAppId;
    };
  };
}
