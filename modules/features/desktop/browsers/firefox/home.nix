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

  shared = import ./settings.nix { inherit lib; };
  inherit (shared) privacyToSettings uiToSettings;

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
      darwinDefaultsId = if isDarwin then null else "org.mozilla.firefox";

      inherit (shared) policies;

      profiles.default = lib.mkIf (!isDarwin) {
        id = 0;
        name = "default";

        settings =
          lib.mapAttrs (
            name: value:
            if builtins.elem name shared.lockedPreferences then lib.mkForce value else value
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

        extensions.packages = map (extension: extension.package) (
          shared.extensions
            inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}
        );
      };

      betterfox = lib.mkIf (!isDarwin && cfg.betterfox.enable) {
        enable = true;
        profiles.default = shared.betterfoxProfile cfg.betterfox;
      };
    };
  };
}
