{
  config,
  namespace,
  ...
}:
let
  _cfg = config.${namespace}.system.dock;
in
{
  config.system.defaults = {
    dock = {
      autohide = true;
      expose-group-apps = true; # shows all apps instead of per-space
      largesize = 88;
      magnification = true;
      mineffect = "scale";
      orientation = "left";
      show-process-indicators = true;
      show-recents = false;
      showhidden = false; # hide the hidden lol
      static-only = false; # allow unopened apps to be shown
      tilesize = 40;
    };

    CustomUserPreferences.NSGlobalDomain."com.apple.dock" = {
      ## gestures
      showAppExposeGestureEnabled = 0;

      # 3f up for mission-control
      showMissionControlGestureEnabled = 1;

      # 3f shows launchpad
      showLaunchpadGestureEnabled = 0;

      # 3f shows desktop
      showDesktopGestureEnabled = 0;
    };
  };
}
