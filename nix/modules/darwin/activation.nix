{
  system,
  ...
}:
{
  config.system.activationScripts = {
    xcodeInstall.text = "xcode-select --print-path >/dev/null 2>&1 || xcode-select --install >/dev/null 2>&1";
    rosettaInstall = {
      enable = system == "aarch64-darwin";
      text = "pgrep oahd >/dev/null 2>&1 || softwareupdate --install-rosetta --agree-to-license >/dev/null 2>&1";
    };

    # allows applying settings to current session, no logout
    postUserActivation.text = ''
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };
}
