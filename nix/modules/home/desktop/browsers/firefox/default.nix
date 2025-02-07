{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.desktop.browsers.firefox;
in
{
  imports = [
    ./engines.nix
    ./extensions.nix
    ./settings.nix
  ];

  options.${namespace}.desktop.browsers.firefox = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package = if pkgs.stdenvNoCC.isDarwin then pkgs.emptyDirectory else pkgs.firefox;

      profiles.default = {
        id = 0; # default
        name = "default";

        search = {
          default = "DuckDuckGo";
          force = true;
        };
      };
    };
  };
}
