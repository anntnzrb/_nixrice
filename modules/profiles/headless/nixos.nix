# Machines tagged `headless`: no X, never sleep, performance governor.
{ pkgs, ... }: {
  services.xserver.enable = false;
  powerManagement.cpuFreqGovernor = "performance";

  # stay reachable: never sleep on lid close or idle
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    LidSwitchIgnoreInhibited = "no";
    IdleAction = "ignore";
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  environment.systemPackages = with pkgs; [
    cpufrequtils
    linuxPackages.cpupower
  ];

  # no man pages either (base already drops doc/info and the NixOS manual)
  documentation.enable = false;
}
