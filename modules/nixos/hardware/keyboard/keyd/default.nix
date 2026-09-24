{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.hardware.keyboard.keyd;
in
{
  options.${namespace}.hardware.keyboard.keyd = {
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
