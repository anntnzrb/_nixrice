{ self
, me
, inputs
, lib
, config
, pkgs
, hostInfo
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

  imports = sharedImports ++ [
    inputs.home-manager.nixosModules.home-manager

    ./hardware
    ./network.nix
    ./display.nix
  ];
in
{
  inherit imports;

  system.stateVersion = "23.05";

  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit self me hostInfo inputs; };
    users = {
      ${hostInfo.user} = import "${me.nixHomes}/${hostInfo.hostName}";
    };
  };

  # ---------------------------------------------------------------------------

  time.timeZone = "America/Guayaquil";
  i18n.defaultLocale = "en_US.UTF-8";
  networking.hostName = "${hostInfo.hostName}";
  boot.loader.systemd-boot.enable = true;

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
