{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.desktop.browsers.firefox;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.desktop.browsers.firefox = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package =
        if pkgs.stdenvNoCC.hostPlatform.isDarwin then
          null
        else
          pkgs.firefox;

      profiles.default = {
        id = 0; # default
        name = "default";

        search = {
          default = "ddg";
          force = true;
        };
      };
    };
  };
}
