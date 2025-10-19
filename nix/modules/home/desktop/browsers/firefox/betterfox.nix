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
        };
      };
    };
  };
}
