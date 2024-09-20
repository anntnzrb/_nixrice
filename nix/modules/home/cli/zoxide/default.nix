{ config, lib, ... }:
let
  cfg = config.liberion.cli.zoxide;
in
{
  options.liberion.cli.zoxide = with lib.liberion; {
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
