{ lib, config, ... }:
let
  user = config.system.primaryUser;
  container = "${config.system.primaryUserHome}/Library/Containers/com.apple.Safari";
  plist = "${container}/Data/Library/Preferences/com.apple.Safari";

  groups = {
    window = {
      ShowFavoritesBar-v2 = false;
      ShowOverlayStatusBar = false;
      ShowSidebarInNewWindows = false;
      NewWindowBehavior = 1;
      HomePage = "about:blank";
    };

    tabs = {
      ShowStandaloneTabBar = false;
      NewTabBehavior = 1;
    };

    toolbar = {
      NeverUseBackgroundColorInToolbar = true;
      ShowFullURLInSmartSearchField = false;
    };

    search = {
      PreloadTopHit = false;
      WebsiteSpecificSearchEnabled = false;
      SuppressSearchSuggestions = true;
      UniversalSearchEnabled = false;
    };

    hygiene = {
      ReadingListSaveArticlesOfflineAutomatically = false;
      AutoOpenSafeDownloads = false;
      DownloadsClearingPolicy = 2;
      HistoryAgeInDaysLimit = 31;
    };

    processes = {
      WebProcessCacheCachedProcessLifetimeInSeconds = 60.0;
      WebProcessCacheClearingDelayAfterApplicationResignsActiveInSeconds = 60.0;
    };

    developer = {
      IncludeDevelopMenu = true;
      WebKitDeveloperExtrasEnabledPreferenceKey = true;
      "WebKitPreferences.developerExtrasEnabled" = true;
    };

    input = {
      WebKitTabToLinksPreferenceKey = false;
      "WebKitPreferences.tabFocusesLinks" = false;
    };
  };

  settings = lib.mergeAttrsList (lib.attrValues groups);

  asUser = lib.liberion.darwin.asUser user;

  writes = lib.concatMapStringsSep "\n" (w: "    ${w}") (
    lib.liberion.darwin.writeDefaults user {
      domain = plist;
      inherit settings;
    }
  );
in
{
  liberion.darwin.owned.defaults = map (key: {
    domain = plist;
    inherit key;
  }) (lib.attrNames settings);

  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [ ! -d ${lib.escapeShellArg container} ]; then
      echo "safari: container missing, open Safari once and switch again" >&2
    elif pgrep -xq Safari; then
      echo "safari: running, quit it and switch again to apply preferences" >&2
    elif ! ${asUser} defaults read ${lib.escapeShellArg plist} >/dev/null 2>&1; then
      echo "safari: cannot read container plist, grant Full Disk Access to this terminal" >&2
    else
    ${writes}
    fi
  '';
}
