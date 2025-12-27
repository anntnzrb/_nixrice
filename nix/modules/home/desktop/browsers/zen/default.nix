{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.desktop.browsers.zen;
in
{
  imports = [ inputs.zen-browser.homeModules.twilight ];

  options.${namespace}.desktop.browsers.zen = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    # Close Zen before activation to prevent database locks (spaces/pins)
    # home.activation.closeZenBeforeActivation = config.lib.dag.entryBefore [
    #   "writeBoundary"
    # ] "pkill -15 zen 2>/dev/null || :";

    programs.zen-browser = {
      inherit (cfg) enable;

      # Required for policies to work on macOS
      darwinDefaultsId = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "app.zen-browser.zen";

      # Mozilla Policy Templates (enterprise policies)
      # https://mozilla.github.io/policy-templates/
      # Zen inherits these from Firefox via mkFirefoxModule
      policies = {
        DisableAppUpdate = true;
        DisableTelemetry = true;
        DisablePocket = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
      };

      # Profile configuration (from home-manager's mkFirefoxModule)
      profiles.default = {
        id = 0;
        name = "default";

        search = {
          default = "perplexity";
          force = true;

          engines = {
            perplexity = {
              name = "Perplexity";
              definedAliases = [
                "@p"
                "@perplexity"
              ];
              icon = "https://www.perplexity.ai/favicon.ico";
              urls = [
                {
                  template = "https://www.perplexity.ai/search";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
            };
          };
        };
      };
    };
  };
}
