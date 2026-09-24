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

  smoothfoxSettingName =
    {
      "sharpen-scrolling" = "sharpen-scrolling";
      "smooth-scrolling" = "smooth-scrolling";
      "instant-scrolling" = "instant-scrolling";
      "natural-smooth-scrolling-v3" = "natural-smooth-scrolling-v3";
    }
    .${cfg.betterfox.smoothfox};
in
{
  imports = [ inputs.betterfox-nix.homeModules.betterfox ];

  config = lib.mkIf (cfg.enable && cfg.betterfox.enable) {
    programs.firefox.betterfox = on // {
      profiles.default = {
        enableAllSections = true;

        settings = lib.optionalAttrs (cfg.betterfox.smoothfox != null) {
          smoothfox.${smoothfoxSettingName}.enable = true;
        };
      };
    };
  };
}
