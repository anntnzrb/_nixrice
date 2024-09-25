{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.browsers.firefox;
in
{
  imports = [
    ./engines.nix
    ./extensions.nix
    ./settings.nix
  ];

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
        };
      };
    };
  };
}
