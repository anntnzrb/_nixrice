{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (lib.${namespace}.launchd.darwin) mkAgent;

  cfg = config.${namespace}.system.keyboard;

  # Apple HID usage IDs. These are the numeric values expected by
  # `hidutil property --set`; nix-darwin forwards them unchanged.
  # Source: Apple Technical Note TN2450, "Remapping Keys in macOS".
  hidKeys = {
    capsLock = 30064771129;
    escape = 30064771113;
  };

  # `hidutil` mappings are volatile: macOS drops them on reboot and may also
  # drop them when keyboard services/devices are recreated. nix-darwin applies
  # `system.keyboard.userKeyMapping` during `darwin-rebuild switch`; the
  # launchd agent below reapplies the same mapping at GUI login.
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
  options.${namespace}.system.keyboard = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
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
            inherit userKeyMapping;
          };
        };
      }

      # Reapply the volatile hidutil mapping after reboot/login. Keep this in
      # addition to nix-darwin's activation script: switch-time and login-time
      # are different failure modes.
      (mkAgent {
        name = "keyboard-user-key-mapping";
        managedBy = "${namespace}.system.keyboard.enable";
        serviceConfig = {
          ProgramArguments = [ "${applyKeyMapping}" ];
          RunAtLoad = true;
          ProcessType = "Interactive";
          LimitLoadToSessionType = [ "Aqua" ];
        };
      })
    ]
  );
}
