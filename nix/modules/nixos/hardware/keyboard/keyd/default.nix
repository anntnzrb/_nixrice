{ lib
, config
, ...
}:
let
  cfg = config.liberion.hardware.keyboard.keyd;
in
{
  options.liberion.hardware.keyboard.keyd = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.keyd = {
      enable = true;

      keyboards.main.settings = {
        "main" = {
          "capslock" = "esc";
        };
      };
    };
  };
}
