{ config, lib, ... }:
let
  cfg = config.liberion.cli.espanso;
in
{
  options.liberion.cli.espanso = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.espanso = {
      enable = true;
    };
  };
}
