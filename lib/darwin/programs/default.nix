{ lib, ... }:
let
  inherit (lib.types) ints str;
in
{
  mkOneCaskProgram =
    { config }:
    name: cask:
    let
      inherit (lib.liberion.module) mkOptDisabled';
      cfg = config.liberion.programs.${name};
    in
    {
      options = lib.setAttrByPath [ "liberion" "programs" name ] {
        enable = mkOptDisabled';
      };

      config = lib.mkIf cfg.enable { liberion.homebrew.packages.casks = [ cask ]; };
    };

  mkOneMasAppProgram =
    { config }:
    name: appName: appId:
    let
      inherit (lib.liberion.module) mkOpt' mkOptDisabled';
      cfg = config.liberion.programs.${name};
    in
    {
      options = lib.setAttrByPath [ "liberion" "programs" name ] {
        enable = mkOptDisabled';
        masAppName = mkOpt' str appName;
        masAppId = mkOpt' ints.positive appId;
      };

      config = lib.mkIf cfg.enable {
        liberion.homebrew.packages.masApps = {
          "${cfg.masAppName}" = cfg.masAppId;
        };
      };
    };
}
