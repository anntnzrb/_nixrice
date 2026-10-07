{ lib, ... }:
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

in
{
  imports = [
    (lib.liberion.darwin.homebrewApps [ "brave" ])
    (lib.liberion.darwin.managedPreferences {
      domain = "com.brave.Browser";
      settings = policies;
    })
  ];
}
