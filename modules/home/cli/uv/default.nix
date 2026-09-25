{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.cli.uv;
in
{
  options.liberion.cli.uv = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable { programs.uv = { inherit (cfg) enable; }; };
}
