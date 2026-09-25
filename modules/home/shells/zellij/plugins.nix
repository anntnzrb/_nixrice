{ lib, config, ... }:
let
  cfg = config.liberion.shells.zellij;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."zellij/config.kdl".text = # kdl
      ''
        plugins {}
      '';
  };
}
