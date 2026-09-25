{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.desktop.obs;
in
{
  options.liberion.desktop.obs = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = { inherit (cfg) enable; };
  };
}
