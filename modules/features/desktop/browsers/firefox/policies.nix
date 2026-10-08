{
  lib,
  cfg,
  policies,
  extensions,
  inputs,
}:
let
  shared = import ./settings.nix { inherit lib; };
  engines = import ./engines.nix;

  preference = status: value: {
    Value = value;
    Status = status;
    Type =
      if builtins.isBool value then
        "boolean"
      else if builtins.isInt value then
        "number"
      else
        "string";
  };

  betterfox =
    lib.optionalAttrs cfg.betterfox.enable
      (lib.evalModules {
        modules = [
          inputs.betterfox-nix.homeModules.betterfox
          {
            options.assertions = lib.mkOption {
              type = lib.types.listOf lib.types.anything;
            };
            options.programs.firefox.profiles = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
            };
            config.programs.firefox.betterfox.profiles.default =
              shared.betterfoxProfile cfg.betterfox;
          }
        ];
      }).config.programs.firefox.betterfox.profiles.default.flatSettings;

  preferences =
    lib.mapAttrs (_: preference "default") (shared.uiToSettings cfg.ui)
    // lib.mapAttrs (_: preference "default") betterfox
    // lib.mapAttrs (
      name: value:
      preference (
        if builtins.elem name shared.lockedPreferences then "locked" else "user"
      ) value
    ) (shared.privacyToSettings cfg.privacy)
    // {
      "extensions.autoDisableScopes" = preference "user" 0;
    };

  sanitize = cfg.privacy.sanitizeOnShutdown;
  privacy = shared.privacyToSettings cfg.privacy;
  dedicatedPolicyPreferences = lib.filter (
    name:
    lib.hasPrefix "privacy.sanitize." name
    || lib.hasPrefix "privacy.clearOnShutdown" name
    || name == "identity.fxaccounts.enabled"
  ) (lib.attrNames preferences);

  searchEngine =
    engine:
    let
      url = lib.head engine.urls;
      params = lib.concatMapStringsSep "&" (
        param: "${param.name}=${param.value}"
      ) url.params;
    in
    {
      Name = engine.name;
      URLTemplate =
        url.template
        + lib.optionalString (params != "") (
          (if lib.hasInfix "?" url.template then "&" else "?") + params
        );
      Method = "GET";
      IconURL = engine.icon;
      Alias = lib.head engine.definedAliases;
    };
in
policies
// {
  EnterprisePoliciesEnabled = true;
  Preferences = removeAttrs preferences dedicatedPolicyPreferences;
  DisableFirefoxAccounts = cfg.privacy.disableSync;
  SanitizeOnShutdown =
    if sanitize.enable then
      {
        Cache = sanitize.cache;
        Cookies = sanitize.cookies;
        History = sanitize.history;
        Downloads = privacy."privacy.clearOnShutdown.downloads";
        OfflineApps = privacy."privacy.clearOnShutdown.offlineApps";
        FormData = privacy."privacy.clearOnShutdown.formdata";
        Sessions = privacy."privacy.clearOnShutdown.sessions";
        SiteSettings = privacy."privacy.clearOnShutdown.siteSettings";
        Locked = false;
      }
    else
      false;
  ExtensionSettings = lib.listToAttrs (
    map (
      extension:
      lib.nameValuePair extension.package.addonId {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/${extension.slug}/latest.xpi";
      }
    ) extensions
  );
  SearchEngines = {
    Add = map searchEngine (lib.attrValues engines);
    Default =
      if cfg.search.default == "ddg" then
        "DuckDuckGo"
      else
        engines.${cfg.search.default}.name or cfg.search.default;
  };
}
