{ lib, config, ... }:
let
  asUser = lib.liberion.darwin.asUser config.system.primaryUser;
  owners = config.liberion.darwin.launcherHotkey.owners;
in
{
  options.liberion.darwin.launcherHotkey.owners =
    lib.liberion.module.mkOpt' (lib.types.listOf lib.types.str)
      [ ];

  config = lib.mkIf (owners != [ ]) {
    assertions = [
      {
        assertion = lib.length owners == 1;
        message = "Cmd+Space is claimed by several launchers (${lib.concatStringsSep ", " owners}); give it to exactly one.";
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
