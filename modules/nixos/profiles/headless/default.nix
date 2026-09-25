{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.profiles.headless;
in
{
  options.${namespace}.profiles.headless = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
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

    # shared/nix already pins doc/info off; nixos docs are the only nested
    # write that is not duplicated elsewhere
    documentation = {
      enable = false;
      nixos.enable = false;
    };
  };
}
