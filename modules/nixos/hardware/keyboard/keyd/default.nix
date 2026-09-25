{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.hardware.keyboard.keyd;
in
{
  options.liberion.hardware.keyboard.keyd = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.keyd = {
      inherit (cfg) enable;

      keyboards.main.settings = {
        "main" = {
          "capslock" = "esc";
        };
      };
    };
  };
}
