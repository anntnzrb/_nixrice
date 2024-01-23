{ config
, lib
, ...
}:
let
  cfg = config.liberion.common.displays;

  profiles = {
    munich = import ./munich.nix;
    solna = import ./solna.nix;
  };
in
{
  options.liberion.common.displays = with lib.liberion; with lib.types; {
    enable = mkOptBool';

    profile = mkOpt' str config.networking.hostName;
  };

  config = lib.mkIf cfg.enable {
    services.autorandr = {
      enable = true;
      profiles = profiles."${cfg.profile}".profiles;
    };
  };
}
