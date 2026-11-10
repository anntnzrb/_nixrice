{ config, lib, ... }:
let
  inherit (config.liberion.darwin.owned) shell;
  asUser = lib.liberion.darwin.asUser config.system.primaryUser;
in
{
  imports = [ (lib.liberion.darwin.homebrewApps [ "herdr-app" ]) ];

  # Root deploy agents must enter the GUI bootstrap domain before setting its environment.
  system.activationScripts.postActivation.text = lib.mkIf (shell != null) (
    lib.mkAfter ''
      ${asUser} /bin/launchctl setenv SHELL ${lib.escapeShellArg shell}
    ''
  );
}
