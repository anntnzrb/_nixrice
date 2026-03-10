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

  cfg = config.${namespace}.programs.whatsapp;
in
{
  options.${namespace}.programs.whatsapp = {
    enable = mkOptDisabled';
    masAppName = mkOpt' str "WhatsApp Messenger";
    masAppId = mkOpt' ints.positive 310633997;
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.homebrew.packages.masApps = {
      "${cfg.masAppName}" = cfg.masAppId;
    };
  };
}
