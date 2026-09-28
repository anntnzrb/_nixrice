{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.zen-browser.homeModules.twilight ];

  programs.zen-browser = {
    enable = true;

    darwinDefaultsId = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "app.zen-browser.zen";
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
}
