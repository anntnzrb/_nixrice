{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.system.trackpad;
in
{
  options.${namespace}.system.trackpad = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    system.defaults = {
      trackpad =
        let
          pressure = {
            light = 0;
            medium = 1;
            firm = 2;
          };
        in
        {
          ActuationStrength = 1;
          Clicking = true;
          Dragging = true;
          FirstClickThreshold = pressure.medium;
          SecondClickThreshold = pressure.medium;
          TrackpadRightClick = true;
        };

      NSGlobalDomain = {
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.swipescrolldirection" = true;
        "com.apple.trackpad.enableSecondaryClick" = true;
        AppleEnableMouseSwipeNavigateWithScrolls = true;

        "com.apple.trackpad.scaling" = 0.6875;
      };

      ".GlobalPreferences"."com.apple.mouse.scaling" = -1.0;
    };
  };
}
