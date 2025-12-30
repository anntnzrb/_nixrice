{
  lib,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;

  cfg = config.${namespace}.desktop.browsers.firefox;
in
{
  imports = [ inputs.betterfox-nix.homeModules.betterfox ];

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      betterfox = on // {
        profiles.default = {
          enableAllSections = true;

          settings = {
            # snappy scrolling (60Hz)
            smoothfox.sharpen-scrolling.enable = true;
          };
        };
      };

      profiles.default.settings = {
        # clear cache on close
        "privacy.sanitize.sanitizeOnShutdown" = true;
        "privacy.clearOnShutdown_v2.cache" = true;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
      };
    };
  };
}
