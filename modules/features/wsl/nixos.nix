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
  };

  # NixOS-WSL forces graphics on; Windows supplies the GPU driver (wsl.wslLib), mesa adds ~800 MiB for nothing
  hardware.graphics.package = pkgs.emptyDirectory;

  environment = {
    systemPackages = [ pkgs.wsl-open ];
    sessionVariables.BROWSER = lib.getExe pkgs.wsl-open;
  };

  nix.channel.enable = false;

  clan.core.settings.state-version.enable = true;

  programs.nix-ld.enable = true;
}
