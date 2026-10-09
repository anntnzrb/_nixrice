{ config, lib, ... }:
let
  cfg = config.liberion.darwin.launcher-hotkey.owners;
  asUser = lib.liberion.darwin.asUser config.system.primaryUser;
in
{
  options.liberion.darwin.launcher-hotkey.owners =
    lib.liberion.module.mkOpt' (lib.types.listOf lib.types.str)
      [ ];

  config = lib.mkIf (cfg != [ ]) {
    assertions = [
      {
        assertion = lib.length cfg == 1;
        message = "Cmd+Space is claimed by several launchers (${lib.concatStringsSep ", " cfg}); give it to exactly one.";
      }
    ];

    liberion.darwin.owned.defaults = [
      {
        domain = "com.apple.symbolichotkeys";
        key = "AppleSymbolicHotKeys";
        path = [ "64" ];
      }
    ];

    system.activationScripts.postActivation.text = lib.mkAfter ''
      ${asUser} defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
        -dict-add 64 '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
      ${asUser} ${lib.liberion.darwin.activateSettings}
    '';
  };
}
