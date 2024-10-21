{ config, namespace, ... }:
let
  _cfg = config.${namespace}.system.finder;

  searchScope = {
    thisMac = null;
    currentFolder = "SCcf";
  };

  viewStyle = {
    icon = "icnv";
    list = "clmv";
    galery = "Flwv";
  };
in
{
  config = {
    system.defaults = {
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = searchScope.currentFolder;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = viewStyle.list;
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXSortFoldersFirst = true;
      };

      CustomUserPreferences."com.apple.finder" = {
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = true;
        ShowMountedServersOnDesktop = true;
        ShowRemovableMediaOnDesktop = true;

        # finder startup is ~/
        NewWindowTargetPath = "file:///Users/${config.${namespace}.darwin.user.name}/";
        NewWindowTarget = "PfHm";
        # multi-file tab view
        FinderSpawnTab = true;
      };
    };
  };
}
