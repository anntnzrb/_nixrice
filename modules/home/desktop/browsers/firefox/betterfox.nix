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

  config = lib.mkIf (cfg.enable && cfg.betterfox.enable) {
    programs.firefox.betterfox = on // {
      profiles.default = {
        enableAllSections = true;

        settings = lib.optionalAttrs (cfg.betterfox.smoothfox != null) {
          smoothfox.${cfg.betterfox.smoothfox}.enable = true;
        };
      };
    };
  };
}
