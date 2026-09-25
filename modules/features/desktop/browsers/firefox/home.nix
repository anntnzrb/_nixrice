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
  hasFirefoxBin = pkgs ? firefox-bin;

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

  # Convert privacy options to Firefox settings
  privacyToSettings = cfg: {
    "privacy.sanitize.sanitizeOnShutdown" = cfg.sanitizeOnShutdown.enable;
    "privacy.clearOnShutdown.browsingHistoryAndDownloads" = false;
    "privacy.clearOnShutdown_v2.cache" = cfg.sanitizeOnShutdown.cache;
    "privacy.clearOnShutdown_v2.cookiesAndStorage" = cfg.sanitizeOnShutdown.cookies;
    "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = false;
    "privacy.clearOnShutdown_v2.formdata" = false;
    "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" =
      cfg.sanitizeOnShutdown.history;
    "privacy.clearOnShutdown.formdata" = false;
    "privacy.clearOnShutdown.history" = false;
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

  # Convert hide buttons list to CSS selectors
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

  # Generate userChrome.css from UI options
  uiToUserChrome = cfg: ''
    ${lib.optionalString cfg.autoHideToolbar ''
      /* === AUTO-HIDE TOOLBOX === */
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
      /* === HIDE TAB BAR === */
      #TabsToolbar { visibility: collapse !important; }
    ''}

    ${lib.optionalString (cfg.hideButtons != [ ]) ''
      /* === HIDE TOOLBAR BUTTONS === */
      ${buttonsToCss cfg.hideButtons}
    ''}
  '';
in
{
  imports = [ inputs.betterfox-nix.homeModules.betterfox ];

  options.liberion.desktop.browsers.firefox = {
    ui = {
      autoHideToolbar = mkOptDisabled'; # show the nav toolbar on Cmd+L or hover
      hideTabBar = mkOptEnabled'; # horizontal tabs, redundant with vertical ones
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
        enable = mkOptEnabled'; # the new Firefox sidebar
        verticalTabs = mkOptEnabled';
        expandOnHover = mkOptDisabled';
        visibility = mkOpt' (types.enum [
          "always-show"
          "hide-sidebar"
          "expand-on-hover"
        ]) "hide-sidebar";
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
        enable = mkOptEnabled'; # clear data when Firefox closes
        cache = mkOptEnabled';
        cookies = mkOptDisabled';
        history = mkOptDisabled';
      };
      disableSync = mkOptEnabled'; # Firefox Account/Sync
      disableNewTabHighlights = mkOptEnabled'; # "Recent Activity" on new tabs
    };

    betterfox = {
      enable = mkOptEnabled';
      # scrolling preset, null to disable
      smoothfox = mkOpt' (types.nullOr (
        types.enum [
          "sharpen-scrolling"
          "smooth-scrolling"
          "instant-scrolling"
          "natural-smooth-scrolling-v3"
        ]
      )) "sharpen-scrolling";
    };

    search.default = mkOpt' types.str "perplexity";
  };

  config = {
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
      enable = true;
      package = if isDarwin then null else pkgs.firefox;

      profiles.default = {
        id = 0;
        name = "default";

        settings = privacyToSettings cfg.privacy // uiToSettings cfg.ui;
        userChrome = uiToUserChrome cfg.ui;

        search = {
          inherit (cfg.search) default;
          force = true;
          engines = import ./engines.nix;
        };

        extensions.packages =
          with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
            # utils
            ublock-origin # ad-blocker
            #clearurls # broken
            istilldontcareaboutcookies
            sponsorblock

            # ui/ux
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
