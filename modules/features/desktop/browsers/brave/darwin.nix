{ lib, pkgs, ... }:
let
  policies = {
    HighEfficiencyModeEnabled = true;
    MemorySaverModeSavings = 2;
    BatterySaverModeAvailability = 1;
    BackgroundTabFreezingEnabled = true;
    BackgroundModeEnabled = false;
    NetworkPredictionOptions = 2;

    BraveAIChatEnabled = false;
    BraveNewsDisabled = true;
    BraveRewardsDisabled = true;
    BraveTalkDisabled = true;
    BraveVPNDisabled = true;
    BraveWalletDisabled = true;

    BraveP3AEnabled = false;
    BraveStatsPingEnabled = false;
    BraveWebDiscoveryEnabled = false;
  };

  plist = pkgs.writeText "com.brave.Browser.plist" (
    lib.generators.toPlist { escape = true; } policies
  );
in
{
  imports = [ (lib.liberion.darwin.homebrewApps [ "brave" ]) ];
  liberion.darwin.owned.files."/Library/Managed Preferences/com.brave.Browser.plist".restart =
    [ "cfprefsd" ];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    brave_policy_target="/Library/Managed Preferences/com.brave.Browser.plist"
    mkdir -p "/Library/Managed Preferences"
    if ! cmp -s ${plist} "$brave_policy_target"; then
      install -m 0644 -o root -g wheel ${plist} "$brave_policy_target"
      killall cfprefsd >/dev/null 2>&1 || :
    fi
  '';
}
