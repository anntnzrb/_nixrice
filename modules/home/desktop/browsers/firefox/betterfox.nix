{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) on;

  cfg = config.liberion.desktop.browsers.firefox;
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
