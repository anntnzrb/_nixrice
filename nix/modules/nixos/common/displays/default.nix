{ config
, lib
, ...
}:
let
  cfg = config.liberion.common.displays;

  profiles = {
    munich = import ./munich.nix;
  };
in
{
  options.liberion.common.displays = with lib;{
    enable = mkEnableOption "displays";

    profile = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "The display profile to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.autorandr = {
      enable = true;
      profiles = profiles."${cfg.profile}".profiles;
    };
  };
}
