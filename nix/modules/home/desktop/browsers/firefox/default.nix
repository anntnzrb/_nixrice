{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  cfg = config.${namespace}.desktop.browsers.firefox;

  hasFirefoxBin = pkgs ? firefox-bin;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.desktop.browsers.firefox = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = isDarwin -> hasFirefoxBin;
        message = ''
          Firefox on Darwin requires the nixpkgs-firefox-darwin overlay.
        '';
      }
      {
        assertion = !isDarwin -> (pkgs ? firefox);
        message = "Firefox package not found in nixpkgs.";
      }
    ];

    # on darwin, install firefox-bin separately (wrapper not supported)
    home.packages = lib.mkIf isDarwin [ pkgs.firefox-bin ];

    programs.firefox = {
      inherit (cfg) enable;
      package = if isDarwin then null else pkgs.firefox;

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
