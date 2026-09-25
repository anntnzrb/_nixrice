{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.cli.zoxide;
in
{
  options.liberion.cli.zoxide = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable { programs.zoxide = { inherit (cfg) enable; }; };
}
