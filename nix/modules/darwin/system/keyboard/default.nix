{ config
, namespace
, ...
}:
let
  _cfg = config.${namespace}.system.keyboard;
in
{
  config = {
    system = {
      # press-and-hold for accent keys
      # may be disabled to favor key repetition
      defaults.NSGlobalDomain = {
        ApplePressAndHoldEnabled = false;
        InitialKeyRepeat = 15;
        KeyRepeat = 1;
      };
      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToEscape = true;
      };
    };
  };
}
