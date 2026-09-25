{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.cli.repomix;
in
{
  options.liberion.cli.repomix = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.repomix = "${lib.getExe' pkgs.bun "bun"} x repomix@latest --";
  };
}
