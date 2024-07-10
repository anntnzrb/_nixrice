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
          light = 0;
        in
        {
          ActuationStrength = 0;
          Clicking = true;
          Dragging = true;
          FirstClickThreshold = light;
          SecondClickThreshold = light;
          TrackpadRightClick = true;
        };

      NSGlobalDomain = {
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.swipescrolldirection" = true;
        "com.apple.trackpad.enableSecondaryClick" = true;
        AppleEnableMouseSwipeNavigateWithScrolls = true;

        "com.apple.trackpad.scaling" = 2.0;
      };

      ".GlobalPreferences"."com.apple.mouse.scaling" = -1.0;
    };
  };
}
