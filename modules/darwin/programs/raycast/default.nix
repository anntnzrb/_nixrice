{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.programs.raycast;
  user = config.system.primaryUser;
in
{
  options.${namespace}.programs.raycast = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.homebrew.packages.casks = [ "raycast" ];

    # Raycast owns Cmd+Space (49 = space key)
    system.defaults.CustomUserPreferences."com.raycast.macos".raycastGlobalHotkey =
      "Command-49";

    # Release Spotlight's Cmd+Space (symbolic hotkey 64). `-dict-add` edits this
    # one entry; system.defaults would rewrite every macOS shortcut.
    system.activationScripts.postActivation.text = lib.mkAfter ''
      sudo -u ${user} defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
        -dict-add 64 '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
      sudo -u ${user} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };
}
