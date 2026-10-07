{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptEnabled' mkOptDisabled';
  inherit (lib) types;
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  cfg = config.liberion.desktop.browsers.firefox;

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

  buttonsToCss =
    buttons:
    let
      buttonMap = {
        extensions = "#unified-extensions-button";
        alltabs = "#alltabs-button";
        newtab = "#tabs-newtab-button";
        sidebar = "#sidebar-button";
      };
      selectors = map (b: buttonMap.${b}) buttons;
    in
    if selectors == [ ] then
      ""
    else
      "${lib.concatStringsSep ",\n" selectors} { display: none !important; }";

  uiToUserChrome = cfg: ''
    ${lib.optionalString cfg.autoHideToolbar ''
      :root {
        --uc-autohide-toolbox-delay: 200ms;
        --uc-toolbox-rotation: 75deg;
      }

      :root[sizemode="fullscreen"],
      :root[sizemode="fullscreen"] #navigator-toolbox { margin-top: 0 !important; }

      #navigator-toolbox {
        position: fixed !important;
        background-color: var(--lwt-accent-color, black) !important;
        transition: transform 82ms linear, opacity 82ms linear !important;
        transition-delay: var(--uc-autohide-toolbox-delay) !important;
        transform-origin: top;
        transform: rotateX(var(--uc-toolbox-rotation));
        opacity: 0;
        line-height: 0;
        z-index: 1;
        pointer-events: none;
        width: 100vw;
      }

      :root[sessionrestored] #urlbar[popover] {
        pointer-events: none;
        opacity: 0;
        transition: transform 82ms linear var(--uc-autohide-toolbox-delay), opacity 0ms calc(var(--uc-autohide-toolbox-delay) + 82ms);
        transform-origin: 0px calc(0px - var(--tab-min-height) - var(--tab-block-margin) * 2);
        transform: rotateX(89.9deg);
      }

      #navigator-toolbox:is(:hover, :focus-within) #urlbar[popover],
      #urlbar-container > #urlbar[popover]:is([focused], [open]) {
        pointer-events: auto;
        opacity: 1;
        transition-delay: 33ms;
        transform: rotateX(0deg);
      }

      #navigator-toolbox:is(:hover, :focus-within, [movingtab]) {
        transition-delay: 33ms !important;
        transform: rotateX(0);
        opacity: 1;
      }

      #navigator-toolbox > * { line-height: normal; pointer-events: auto; }
      :root:not([sessionrestored]) #navigator-toolbox { transform: none !important; }
      :root[customizing] #navigator-toolbox {
        position: relative !important;
        transform: none !important;
        opacity: 1 !important;
      }
    ''}

    ${lib.optionalString cfg.hideTabBar ''
      #TabsToolbar { visibility: collapse !important; }
    ''}

    ${lib.optionalString (cfg.hideButtons != [ ]) ''
      ${buttonsToCss cfg.hideButtons}
    ''}
  '';
in
{
  imports = [ inputs.betterfox-nix.homeModules.betterfox ];

  options.liberion.desktop.browsers.firefox = {
    ui = {
      autoHideToolbar = mkOptDisabled';
      hideTabBar = mkOptEnabled';
      hideButtons =
        mkOpt'
          (types.listOf (
            types.enum [
              "extensions"
              "alltabs"
              "newtab"
              "sidebar"
            ]
          ))
          [
            "extensions"
            "alltabs"
            "newtab"
            "sidebar"
          ];

      sidebar = {
        enable = mkOptEnabled';
        verticalTabs = mkOptEnabled';
        expandOnHover = mkOptDisabled';
        visibility = mkOpt' (types.enum [
          "always-show"
          "hide-sidebar"
          "expand-on-hover"
        ]) "always-show";
        position = mkOpt' (types.enum [
          "left"
          "right"
        ]) "left";
        tools =
          mkOpt'
            (types.listOf (
              types.enum [
                "history"
                "bookmarks"
                "syncedtabs"
                "passwords"
              ]
            ))
            [
              "history"
              "bookmarks"
            ];
      };
    };

    privacy = {
      sanitizeOnShutdown = {
        enable = mkOptEnabled';
        cache = mkOptEnabled';
        cookies = mkOptDisabled';
        history = mkOptDisabled';
      };
      disableSync = mkOptEnabled';
      disableNewTabHighlights = mkOptEnabled';
    };

    betterfox = {
      enable = mkOptEnabled';
      smoothfox = mkOpt' (types.nullOr (
        types.enum [
          "sharpen-scrolling"
          "smooth-scrolling"
          "instant-scrolling"
          "natural-smooth-scrolling-v3"
        ]
      )) "sharpen-scrolling";
    };

    search.default = mkOpt' types.str "ddg";
  };

  config = {
    assertions = [
      {
        assertion = !isDarwin -> (pkgs ? firefox);
        message = "Firefox package not found in nixpkgs.";
      }
    ];

    programs.firefox = {
      enable = true;
      package = if isDarwin then null else pkgs.firefox;
      darwinDefaultsId = "org.mozilla.firefox";

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

      profiles.default = {
        id = 0;
        name = "default";

        settings =
          lib.mapAttrs (
            name: value:
            if
              builtins.elem name [
                "browser.formfill.enable"
                "signon.formlessCapture.enabled"
                "signon.privateBrowsingCapture.enabled"
              ]
            then
              lib.mkForce value
            else
              value
          ) (privacyToSettings cfg.privacy)
          // lib.mapAttrs (_: lib.mkDefault) (uiToSettings cfg.ui)
          // {
            "extensions.autoDisableScopes" = 0;
          };
        userChrome = uiToUserChrome cfg.ui;

        search = {
          inherit (cfg.search) default;
          force = true;
          engines = import ./engines.nix;
        };

        extensions.packages =
          with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
            ublock-origin
            istilldontcareaboutcookies
            sponsorblock
            refined-github
          ];
      };

      betterfox = lib.mkIf cfg.betterfox.enable {
        enable = true;
        profiles.default = {
          enableAllSections = true;

          settings = lib.optionalAttrs (cfg.betterfox.smoothfox != null) {
            smoothfox.${cfg.betterfox.smoothfox}.enable = true;
          };
        };
      };
    };
  };
}
