{ lib, pkgs, ... }:
let
  inherit (lib.liberion.identity) keys sshPort;
  userName = lib.liberion.identity.user;
  authorizedKeys = [ keys.admin ] ++ keys.devices;
in
{
  clan.core.enableRecommendedDefaults = true;

  boot = {
    kernelModules = [
      "tcp_bbr"
      "sch_cake"
    ];
    kernel.sysctl = {
      "net.core.default_qdisc" = "cake";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fastopen" = 3;
      "kernel.nmi_watchdog" = 0;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
      "vm.swappiness" = 100;
      "vm.page-cluster" = 0;
    };
  };

  powerManagement.cpuFreqGovernor = "performance";

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  nix = {
    settings = {
      trusted-users = [ userName ];
      keep-outputs = true;
      keep-derivations = true;
      auto-optimise-store = true;
      warn-dirty = false;
    };
    gc = {
      options = "--delete-older-than 14d";
    };
  };

  environment.systemPackages = with pkgs; [
    cpufrequtils
    git
    linuxPackages.cpupower
  ];

  security.sudo.wheelNeedsPassword = false;

  services = {
    openssh = {
      enable = true;
      ports = [
        22
        sshPort
      ];
      openFirewall = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = false;
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      LidSwitchIgnoreInhibited = "no";
      IdleAction = "ignore";
    };
  };

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      22
      sshPort
    ];
  };

  users.users = {
    ${userName} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = authorizedKeys;
    };
    root.openssh.authorizedKeys.keys = authorizedKeys;
  };
}
