{ lib }: {
  uiToSettings =
    cfg:
    lib.optionalAttrs cfg.sidebar.enable { "sidebar.revamp" = true; }
    // lib.optionalAttrs cfg.sidebar.verticalTabs { "sidebar.verticalTabs" = true; }
    // {
      "sidebar.expandOnHover" = cfg.sidebar.expandOnHover;
      "sidebar.visibility" = cfg.sidebar.visibility;
      "sidebar.position_start" = cfg.sidebar.position == "left";
      "sidebar.main.tools" = lib.concatStringsSep "," cfg.sidebar.tools;
    };

  privacyToSettings = cfg: {
    "privacy.sanitize.sanitizeOnShutdown" = cfg.sanitizeOnShutdown.enable;
    "privacy.sanitize.timeSpan" = 0;
    "privacy.sanitize.clearOnShutdown.hasMigratedToNewPrefs2" = true;
    "privacy.sanitize.clearOnShutdown.hasMigratedToNewPrefs3" = true;
    "privacy.clearOnShutdown.cache" = cfg.sanitizeOnShutdown.cache;
    "privacy.clearOnShutdown.cookies" = cfg.sanitizeOnShutdown.cookies;
    "privacy.clearOnShutdown.offlineApps" = cfg.sanitizeOnShutdown.cookies;
    "privacy.clearOnShutdown.downloads" = cfg.sanitizeOnShutdown.history;
    "privacy.clearOnShutdown.sessions" = false;
    "privacy.clearOnShutdown.siteSettings" = false;
    "privacy.clearOnShutdown.openWindows" = false;
    "privacy.clearOnShutdown.browsingHistoryAndDownloads" = false;
    "privacy.clearOnShutdown_v2.cache" = cfg.sanitizeOnShutdown.cache;
    "privacy.clearOnShutdown_v2.cookiesAndStorage" = cfg.sanitizeOnShutdown.cookies;
    "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = false;
    "privacy.clearOnShutdown_v2.formdata" = false;
    "privacy.clearOnShutdown_v2.siteSettings" = false;
    "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" =
      cfg.sanitizeOnShutdown.history;
    "privacy.clearOnShutdown.formdata" = false;
    "privacy.clearOnShutdown.history" = cfg.sanitizeOnShutdown.history;
    "places.history.enabled" = true;
    "browser.formfill.enable" = true;
    "browser.privatebrowsing.autostart" = false;
    "browser.sessionstore.resume_from_crash" = true;
    "signon.rememberSignons" = true;
    "signon.formlessCapture.enabled" = true;
    "signon.privateBrowsingCapture.enabled" = true;
    "identity.fxaccounts.enabled" = !cfg.disableSync;
    "browser.newtabpage.activity-stream.feeds.section.highlights" =
      !cfg.disableNewTabHighlights;
    "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" =
      !cfg.disableNewTabHighlights;
    "browser.newtabpage.activity-stream.section.highlights.includeDownloads" =
      !cfg.disableNewTabHighlights;
    "browser.newtabpage.activity-stream.section.highlights.includePocket" =
      !cfg.disableNewTabHighlights;
    "browser.newtabpage.activity-stream.section.highlights.includeVisited" =
      !cfg.disableNewTabHighlights;
  };

  policies = {
    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableFeedbackCommands = true;
    DontCheckDefaultBrowser = true;
    NoDefaultBookmarks = true;
    "3rdparty".Extensions."uBlock0@raymondhill.net".toOverwrite.filterLists = [
      "user-filters"
      "ublock-filters"
      "ublock-badware"
      "ublock-privacy"
      "ublock-quick-fixes"
      "ublock-unbreak"
      "easylist"
      "easyprivacy"
      "urlhaus-1"
      "plowe-0"
      "ublock-annoyances"
      "ublock-cookies-easylist"
      "fanboy-cookiemonster"
      "fanboy-social"
      "easylist-chat"
      "easylist-newsletters"
      "easylist-notifications"
      "easylist-annoyances"
      "fanboy-ai-suggestions"
    ];
  };

  lockedPreferences = [
    "browser.formfill.enable"
    "signon.formlessCapture.enabled"
    "signon.privateBrowsingCapture.enabled"
  ];

  hiddenSearchEngines = {
    bing = "Bing";
    ebay = "eBay";
  };

  betterfoxProfile = cfg: {
    enableAllSections = true;
    settings = lib.optionalAttrs (cfg.smoothfox != null) {
      smoothfox.${cfg.smoothfox}.enable = true;
    };
  };

  extensions =
    packages:
    map
      (name: {
        package = packages.${name};
        slug = if name == "refined-github" then "refined-github-" else name;
      })
      [
        "ublock-origin"
        "istilldontcareaboutcookies"
        "sponsorblock"
        "refined-github"
      ];
}
