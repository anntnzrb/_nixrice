{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.system.finder;

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
  options.liberion.system.finder = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
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

        # multi-file tab view
        FinderSpawnTab = true;
      };
    };
  };
}
