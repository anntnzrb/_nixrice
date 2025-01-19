{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.hardware.keyboard.keyd;
in
{
  options.${namespace}.hardware.keyboard.keyd = with lib.${namespace}; {
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
