{ self
, me
, hostInfo
, ...
}: {
  # home-manager handles itself
  programs.home-manager.enable = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  home = {
    username = "${hostInfo.user}";
    homeDirectory = "/home/${hostInfo.user}";
  };

  # reload services on switch
  systemd.user.startServices = "sd-switch";
}
