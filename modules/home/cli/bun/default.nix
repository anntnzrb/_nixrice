{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.cli.bun;
in
{
  options.liberion.cli.bun = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable { programs.bun = { inherit (cfg) enable; }; };
}
