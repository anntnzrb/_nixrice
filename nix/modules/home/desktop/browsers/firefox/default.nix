{
  config,
  lib,
  pkgs,
  inputs,
  system,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.browsers.firefox;
in
{
  options.${namespace}.desktop.browsers.firefox = with lib.${namespace}; {
    enable = mkOptBool';
    package.install = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package = if cfg.package.install then pkgs.firefox else null;

      profiles.default = {
        id = 0; # default
        name = "default";

        search = {
          default = "DuckDuckGo";
          force = true;

          engines = import ./engines.nix;
        };

        extensions = import ./extensions.nix { inherit inputs system; };
        settings = import ./settings.nix;
      };
    };
  };
}
