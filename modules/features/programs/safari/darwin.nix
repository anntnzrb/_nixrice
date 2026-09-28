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

  typeFlag =
    value:
    if lib.isBool value then
      "-bool"
    else if lib.isInt value then
      "-int"
    else if lib.isFloat value then
      "-float"
    else
      "-string";

  render =
    value: if lib.isBool value then lib.boolToString value else toString value;

  asUser = ''launchctl asuser "$(id -u -- ${user})" sudo --user=${user} --'';

  writes = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      key: value:
      "    ${asUser} defaults write ${lib.escapeShellArg plist} ${lib.escapeShellArg key} ${typeFlag value} ${lib.escapeShellArg (render value)}"
    ) settings
  );
in
{
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
