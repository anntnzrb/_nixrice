{ pkgs
, ...
}: {
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];
}
