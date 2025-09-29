{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.system.keyboard;
in
{
  options.${namespace}.system.keyboard = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
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
