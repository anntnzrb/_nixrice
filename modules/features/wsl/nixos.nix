{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  wsl = {
    enable = true;
    defaultUser = lib.liberion.identity.user;
    docker-desktop.enable = true;
    useWindowsDriver = true;
    ssh-agent.enable = true;
    tarball.configPath = ./_etc-nixos;
  };

  # WSL init runs /bin/mount and /bin/sh before systemd; envfs only mounts over /bin once systemd is up
  services.envfs.enable = lib.mkForce false;

  # WSL links /etc/localtime to /usr/share/zoneinfo/<Windows zone> at boot
  time.timeZone = lib.mkForce null;
  systemd.tmpfiles.rules = [
    "L+ /usr/share/zoneinfo - - - - ${pkgs.tzdata}/share/zoneinfo"
  ];

  # NixOS-WSL forces graphics on; Windows supplies the GPU driver (wsl.wslLib), mesa adds ~800 MiB for nothing
  hardware.graphics.package = pkgs.emptyDirectory;

  environment = {
    systemPackages = [ pkgs.wsl-open ];
    sessionVariables.BROWSER = lib.getExe pkgs.wsl-open;
  };

  # systemd classifies WSL as a container, so the stock !container condition skips fstrim; the VHDX only shrinks when the guest discards
  systemd = {
    services.fstrim.unitConfig.ConditionVirtualization = "";
    timers.fstrim.unitConfig.ConditionVirtualization = "";
  };

  nix = {
    channel.enable = false;
    settings.auto-optimise-store = true;
    # bare nixos-rebuild resolves <nixos-config>; point it at the shipped guard
    nixPath = [
      "nixpkgs=flake:nixpkgs"
      "nixos-config=/etc/nixos/configuration.nix"
    ];
  };

  clan.core.settings.state-version.enable = true;

  programs.nix-ld.enable = true;
}
