{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.liberion.module) mkOpt';

  cfg = config.liberion.darwin;
  defaults = config.system.defaults;
  user = config.system.primaryUser;
  home = config.system.primaryUserHome;

  systemDomains = {
    loginwindow = [ "/Library/Preferences/com.apple.loginwindow" ];
    smb = [ "/Library/Preferences/SystemConfiguration/com.apple.smb.server" ];
    SoftwareUpdate = [ "/Library/Preferences/com.apple.SoftwareUpdate" ];
  };

  userDomains = {
    ".GlobalPreferences" = [ ".GlobalPreferences" ];
    LaunchServices = [ "com.apple.LaunchServices" ];
    NSGlobalDomain = [ "-g" ];
    menuExtraClock = [ "com.apple.menuextra.clock" ];
    dock = [ "com.apple.dock" ];
    finder = [ "com.apple.finder" ];
    hitoolbox = [ "com.apple.HIToolbox" ];
    iCal = [ "com.apple.iCal" ];
    magicmouse = [
      "com.apple.AppleMultitouchMouse"
      "com.apple.driver.AppleMultitouchMouse.mouse"
    ];
    screencapture = [ "com.apple.screencapture" ];
    screensaver = [ "com.apple.screensaver" ];
    spaces = [ "com.apple.spaces" ];
    trackpad = [
      "com.apple.AppleMultitouchTrackpad"
      "com.apple.driver.AppleBluetoothMultitouch.trackpad"
    ];
    universalaccess = [ "com.apple.universalaccess" ];
    ActivityMonitor = [ "com.apple.ActivityMonitor" ];
    WindowManager = [ "com.apple.WindowManager" ];
    controlcenter = [
      "${home}/Library/Preferences/ByHost/com.apple.controlcenter"
    ];
  };

  customScopes = [
    "CustomSystemPreferences"
    "CustomUserPreferences"
  ];

  # nix-darwin keeps `alf` only as removed-option stubs; reading it throws.
  ignoredScopes = [ "alf" ];

  unmappedScopes = lib.subtractLists (
    lib.attrNames systemDomains
    ++ lib.attrNames userDomains
    ++ customScopes
    ++ ignoredScopes
  ) (lib.attrNames defaults);

  canonical =
    domain:
    if
      builtins.elem domain [
        "NSGlobalDomain"
        "-globalDomain"
        ".GlobalPreferences"
      ]
    then
      "-g"
    else
      domain;

  restartFor = domain: lib.optional (domain == "com.apple.dock") "Dock";

  keysOf = attrs: lib.attrNames (lib.filterAttrs (_: v: v != null) attrs);

  ownDomain =
    scope: currentHost: domain: attrs:
    map (key: {
      inherit scope currentHost key;
      domain = canonical domain;
      restart = restartFor (canonical domain);
    }) (keysOf attrs);

  scopeAttrs =
    name:
    if name == "dock" then
      removeAttrs defaults.dock [ "expose-group-by-app" ]
    else
      defaults.${name};

  ownTable =
    scope: table:
    lib.concatLists (
      lib.mapAttrsToList (
        name: domains:
        lib.concatMap (d: ownDomain scope false d (scopeAttrs name)) domains
      ) table
    );

  ownCustom =
    scope: currentHost: domains:
    lib.concatLists (lib.mapAttrsToList (ownDomain scope currentHost) domains);

  withId =
    kind: entry:
    let
      full = {
        inherit kind;
      }
      // entry;
    in
    full // { id = builtins.toJSON (removeAttrs full [ "restart" ]); };

  defaultsEntries = map (e: withId "defaults" ({ path = [ ]; } // e)) (
    ownTable "system" systemDomains
    ++ ownTable "user" userDomains
    ++ ownCustom "system" false defaults.CustomSystemPreferences
    ++ ownCustom "user" false defaults.CustomUserPreferences
    ++ ownCustom "user" true cfg.defaults.currentHost
    ++ cfg.owned.defaults
  );

  privacyEntries = map (
    p:
    withId "privacy" {
      inherit (p) service bundleId;
      restart = [ ];
    }
  ) cfg.owned.privacy;

  fileEntries = lib.mapAttrsToList (
    file: o:
    withId "file" {
      inherit file;
      inherit (o) restart;
    }
  ) cfg.owned.files;

  shellEntries = lib.optional (cfg.owned.shell != null) (
    withId "shell" {
      inherit (cfg.owned) shell;
      restart = [ ];
    }
  );

  manifest = pkgs.writeText "liberion-owned.json" (
    builtins.toJSON (
      lib.unique (defaultsEntries ++ fileEntries ++ privacyEntries ++ shellEntries)
    )
  );

  reconcile = pkgs.writeShellApplication {
    name = "liberion-reconcile";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = builtins.readFile ./reconcile.sh;
  };

  hostWrites = lib.concatLists (
    lib.mapAttrsToList (
      domain: settings:
      lib.liberion.darwin.writeDefaults user {
        inherit domain settings;
        currentHost = true;
      }
    ) cfg.defaults.currentHost
  );

  plistValue =
    with types;
    nullOr (oneOf [
      bool
      int
      float
      str
      (attrsOf plistValue)
      (listOf plistValue)
    ])
    // {
      description = "plist value";
    };

  restartOpt = mkOpt' (types.listOf types.str) [ ];

  ownedDefault = types.submodule {
    options = {
      domain = lib.mkOption { type = types.str; };
      key = lib.mkOption { type = types.str; };
      path = mkOpt' (types.listOf types.str) [ ];
      scope = mkOpt' (types.enum [
        "user"
        "system"
      ]) "user";
      currentHost = mkOpt' types.bool false;
      restart = restartOpt;
    };
  };

  ownedPrivacy = types.submodule {
    options = {
      service = lib.mkOption {
        type = types.enum [
          "Accessibility"
          "AppleEvents"
          "Calendar"
          "Camera"
          "Contacts"
          "ListenEvent"
          "Microphone"
          "Photos"
          "PostEvent"
          "Reminders"
          "ScreenCapture"
          "SystemPolicyAllFiles"
          "SystemPolicyDesktopFolder"
          "SystemPolicyDocumentsFolder"
          "SystemPolicyDownloadsFolder"
        ];
      };
      bundleId = lib.mkOption { type = types.str; };
    };
  };
in
{
  options.liberion.darwin = {
    defaults.currentHost = mkOpt' (types.attrsOf (types.attrsOf plistValue)) { };
    owned = {
      defaults = mkOpt' (types.listOf ownedDefault) [ ];
      privacy = mkOpt' (types.listOf ownedPrivacy) [ ];
      files = mkOpt' (types.attrsOf (
        types.submodule { options.restart = restartOpt; }
      )) { };
      shell = mkOpt' (types.nullOr types.path) null;
    };
  };

  config = {
    assertions = [
      {
        assertion = unmappedScopes == [ ];
        message = "modules/base/reconcile: map system.defaults scopes ${builtins.toJSON unmappedScopes} to their defaults domains";
      }
    ];

    system.activationScripts.extraActivation.text = lib.mkAfter ''
      echo >&2 "reconciling owned state..."
      ${lib.getExe reconcile} /var/lib/liberion/owned.json ${manifest} ${lib.escapeShellArg user} \
        || echo >&2 "reconcile: failed, keeping the previous record to retry on the next switch"
    '';

    system.activationScripts.postActivation.text = lib.mkAfter (
      lib.concatStringsSep "\n" hostWrites
    );
  };
}
