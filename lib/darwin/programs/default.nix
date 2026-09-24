{ lib, ... }:
let
  inherit (lib.types) ints str;
in
{
  mkOneCaskProgram =
    { config, namespace }:
    name: cask:
    let
      inherit (lib.${namespace}.module) mkOptDisabled';
      cfg = config.${namespace}.programs.${name};
    in
    {
      options = lib.setAttrByPath [ namespace "programs" name ] {
        enable = mkOptDisabled';
      };

      config = lib.mkIf cfg.enable {
        ${namespace}.homebrew.packages.casks = [ cask ];
      };
    };

  mkOneMasAppProgram =
    { config, namespace }:
    name: appName: appId:
    let
      inherit (lib.${namespace}.module) mkOpt' mkOptDisabled';
      cfg = config.${namespace}.programs.${name};
    in
    {
      options = lib.setAttrByPath [ namespace "programs" name ] {
        enable = mkOptDisabled';
        masAppName = mkOpt' str appName;
        masAppId = mkOpt' ints.positive appId;
      };

      config = lib.mkIf cfg.enable {
        ${namespace}.homebrew.packages.masApps = {
          "${cfg.masAppName}" = cfg.masAppId;
        };
      };
    };
}
