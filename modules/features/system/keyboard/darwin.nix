{ lib, pkgs, ... }:
let
  hidKeys = {
    capsLock = 30064771129;
    escape = 30064771113;
  };

  userKeyMapping = [
    {
      HIDKeyboardModifierMappingSrc = hidKeys.capsLock;
      HIDKeyboardModifierMappingDst = hidKeys.escape;
    }
  ];

  hidutilPayload = builtins.toJSON { UserKeyMapping = userKeyMapping; };

  applyKeyMapping = pkgs.writeShellScript "apply-keyboard-user-key-mapping" ''
    /usr/bin/hidutil property --set '${hidutilPayload}' >/dev/null
  '';
in
{
  config = lib.mkMerge [
    {
      system = {
        defaults.NSGlobalDomain = {
          ApplePressAndHoldEnabled = false;
          InitialKeyRepeat = 15;
          KeyRepeat = 1;
        };
        keyboard = {
          enableKeyMapping = true;
          inherit userKeyMapping;
        };
      };
    }

    {
      launchd.user.agents.keyboard-user-key-mapping = {
        managedBy = "modules/features/system/keyboard";
        serviceConfig = {
          ProgramArguments = [ "${applyKeyMapping}" ];
          RunAtLoad = true;
          ProcessType = "Interactive";
          LimitLoadToSessionType = [ "Aqua" ];
        };
      };
    }
  ];
}
