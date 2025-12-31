{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' getModuleFiles;
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  firefoxLib = import ./lib.nix { inherit lib; };
  cfg = config.${namespace}.desktop.browsers.firefox;
  hasFirefoxBin = pkgs ? firefox-bin;
in
{
  imports = getModuleFiles {
    path = ./.;
    ignore = [ "lib.nix" ];
  };

  options.${namespace}.desktop.browsers.firefox = {
    enable = mkOptDisabled';

    ui = firefoxLib.mkUiOptions;
    privacy = firefoxLib.mkPrivacyOptions;
    betterfox = firefoxLib.mkBetterfoxOptions;
    search = firefoxLib.mkSearchOptions;
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = isDarwin -> hasFirefoxBin;
        message = ''
          Firefox on Darwin requires the nixpkgs-firefox-darwin overlay.
          Add 'inputs.nixpkgs-firefox-darwin.overlay' to your flake overlays.
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
        id = 0;
        name = "default";
      };
    };
  };
}
