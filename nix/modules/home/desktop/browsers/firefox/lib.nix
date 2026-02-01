# Firefox module type definitions and helpers
{ lib }:
let
  inherit (lib) types mkOption mkEnableOption;

  # ---------------------------------------------------------------------------
  # Types
  # ---------------------------------------------------------------------------

  sidebarVisibility = types.enum [
    "always-show"
    "hide-sidebar"
    "expand-on-hover"
  ];

  sidebarPosition = types.enum [
    "left"
    "right"
  ];

  sidebarTool = types.enum [
    "history"
    "bookmarks"
    "syncedtabs"
    "passwords"
  ];

  smoothfoxPreset = types.enum [
    "sharpen-scrolling"
    "smooth-scrolling"
    "instant-scrolling"
    "natural-smooth-scrolling-v3"
  ];

  # ---------------------------------------------------------------------------
  # Option Builders
  # ---------------------------------------------------------------------------

  # UI options
  mkUiOptions = {
    autoHideToolbar = mkEnableOption "auto-hide navigation toolbar (show on Cmd+L or hover)";

    hideTabBar = mkOption {
      type = types.bool;
      default = true;
      description = "Hide horizontal tab bar (when using vertical tabs)";
    };

    hideButtons = mkOption {
      type = types.listOf (
        types.enum [
          "extensions"
          "alltabs"
          "newtab"
          "sidebar"
        ]
      );
      default = [
        "extensions"
        "alltabs"
        "newtab"
        "sidebar"
      ];
      description = "Toolbar buttons to hide";
    };

    sidebar = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable the new Firefox sidebar";
      };

      verticalTabs = mkOption {
        type = types.bool;
        default = true;
        description = "Enable native vertical tabs";
      };

      expandOnHover = mkOption {
        type = types.bool;
        default = false;
        description = "Expand sidebar when hovering over it";
      };

      visibility = mkOption {
        type = sidebarVisibility;
        default = "hide-sidebar";
        description = "Sidebar visibility mode";
      };

      position = mkOption {
        type = sidebarPosition;
        default = "left";
        description = "Sidebar position (left or right)";
      };

      tools = mkOption {
        type = types.listOf sidebarTool;
        default = [
          "history"
          "bookmarks"
        ];
        description = "Tools to show in sidebar";
      };
    };
  };

  # Privacy options
  mkPrivacyOptions = {
    sanitizeOnShutdown = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Clear data when Firefox closes";
      };

      cache = mkOption {
        type = types.bool;
        default = true;
        description = "Clear cache on shutdown";
      };

      cookies = mkOption {
        type = types.bool;
        default = false;
        description = "Clear cookies on shutdown";
      };

      history = mkOption {
        type = types.bool;
        default = false;
        description = "Clear history on shutdown";
      };
    };

    disableSync = mkOption {
      type = types.bool;
      default = true;
      description = "Disable Firefox Account/Sync";
    };

    disableNewTabHighlights = mkOption {
      type = types.bool;
      default = true;
      description = "Disable 'Recent Activity' on new tab page";
    };
  };

  # Betterfox options
  mkBetterfoxOptions = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Betterfox optimizations";
    };

    smoothfox = mkOption {
      type = types.nullOr smoothfoxPreset;
      default = "sharpen-scrolling";
      description = "Smoothfox scrolling preset (null to disable)";
    };
  };

  # Search engine options
  mkSearchOptions = {
    default = mkOption {
      type = types.str;
      default = "perplexity";
      description = "Default search engine name";
    };
  };

  # ---------------------------------------------------------------------------
  # Converters (options → about:config settings)
  # ---------------------------------------------------------------------------

  # Convert UI options to Firefox settings
  uiToSettings =
    cfg:
    lib.optionalAttrs cfg.sidebar.enable {
      "sidebar.revamp" = true;
    }
    // lib.optionalAttrs cfg.sidebar.verticalTabs {
      "sidebar.verticalTabs" = true;
    }
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
  inherit
    sidebarVisibility
    sidebarPosition
    sidebarTool
    smoothfoxPreset
    mkUiOptions
    mkPrivacyOptions
    mkBetterfoxOptions
    mkSearchOptions
    uiToSettings
    privacyToSettings
    buttonsToCss
    uiToUserChrome
    ;
}
