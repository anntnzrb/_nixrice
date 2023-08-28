{ pkgs
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
    "virtualisation/docker"
    "ssh"
  ];

  imports = [
    ../default.nix

    inputs.home-manager.nixosModules.home-manager

    ./hardware
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
      extraGroups = [ "wheel" "docker" ];
      initialPassword = " ";

      openssh.authorizedKeys.keyFiles = [
        "${me.dotfilesDir}/ssh/id_ed25519_git.pub"
      ];
    };
  };
}
