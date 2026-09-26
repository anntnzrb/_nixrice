# Machines tagged `server`: always on (never sleeps, performance governor),
# reachable over ssh, tuned for builds.
{ lib, pkgs, ... }:
let
  inherit (lib.liberion.identity) keys sshPort;
  userName = lib.liberion.identity.user;
  authorizedKeys = [ keys.admin ] ++ keys.devices;
in
{
  # server-tagged machines are the clan-installed ones (see clan.nix): take
  # clan's recommended defaults; everything else keeps base's `false`
  clan.core.enableRecommendedDefaults = true;

  # network: bbr congestion control with cake qdisc against bufferbloat
  boot = {
    kernelModules = [
      "tcp_bbr"
      "sch_cake"
    ];
    kernel.sysctl = {
      "net.core.default_qdisc" = "cake";
      "net.ipv4.tcp_congestion_control" = "bbr";
      # tcp fast open for both client and server sockets
      "net.ipv4.tcp_fastopen" = 3;
      "kernel.nmi_watchdog" = 0;
      # flush dirty pages earlier to avoid io latency spikes
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
      # zram has no seek cost: swap eagerly, no readahead
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
      # keep derivations/outputs so offline dev shells survive gc
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

    # resolve and publish .local hostnames over mdns
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    # stay reachable: never sleep on lid close or idle
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
