{ lib
, config
, ...
}:
let
  cfg = config.liberion.desktop.redshift;
in
{
  options.liberion.desktop.redshift = with lib; {
    enable = mkEnableOption "redshift";

    latitude = with types; mkOption {
      type = (nullOr float);
      default = (-2.0);
    };

    longitude = with types; mkOption {
      type = (nullOr float);
      default = (-81.0);
    };

    tray = mkEnableOption "use system tray?";
  };

  config = lib.mkIf cfg.enable {
    services.redshift = {
      enable = true;

      inherit (cfg) latitude longitude tray;

      provider = "manual";
      temperature = {
        day = 5700;
        night = 3500;
      };
    };
  };
}
