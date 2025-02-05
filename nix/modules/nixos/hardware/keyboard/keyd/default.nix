{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.hardware.keyboard.keyd;
in
{
  options.${namespace}.hardware.keyboard.keyd = {
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
