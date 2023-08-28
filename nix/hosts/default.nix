{ self
, me
, hostInfo
, pkgs
, lib
, config
, inputs
, ...
}: {
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

  boot.loader.systemd-boot.enable = true;
  networking.hostName = "${hostInfo.hostName}";

  home-manager = {
    extraSpecialArgs = { inherit self me hostInfo inputs; };
    users = {
      ${hostInfo.user} = import "${me.nixHomes}/${hostInfo.hostName}";
    };
  };
}
