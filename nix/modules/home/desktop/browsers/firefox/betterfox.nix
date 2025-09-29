{
  lib,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ inputs.betterfox-nix.homeModules.betterfox ];

  config.programs.firefox = {
    betterfox = on // {
      profiles.default = {
        enableAllSections = true;
      };
    };
  };
}
