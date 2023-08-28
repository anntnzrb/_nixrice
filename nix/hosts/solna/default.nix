{ self
, pkgs
, me
, hostInfo
, inputs
, ...
}:
let
  sharedImports = map (m: "${me.nixHosts}/shared/${m}") [
    "security/sudo_doas"

    "audio"
    "global"
    "keyring"
    "ssh"
  ];

  imports = [
    ../default.nix

    inputs.home-manager.nixosModules.home-manager

    ./hardware
    ./network.nix
    ./display.nix
  ] ++ sharedImports;
in
{
  inherit imports;

  system.stateVersion = "23.05";

  time.timeZone = "America/Guayaquil";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.fish.enable = true; # needed dupe
  users.users = {
    ${hostInfo.user} = {
      createHome = true;
      home = "/home/${hostInfo.user}";
      shell = pkgs.fish;
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      initialPassword = " ";
    };
  };
}
