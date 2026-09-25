{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.profiles.server;
  userName = config.liberion.user.name;
  inherit (config.liberion.network.ssh) authorizedKeys;
in
{
  options.liberion.profiles.server = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
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
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
    };

    environment.systemPackages = [ pkgs.git ];

    security.sudo.wheelNeedsPassword = false;

    services = {
      openssh = {
        enable = true;
        ports = [
          22
          2222
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
    };

    networking.firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        22
        2222
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
  };
}
