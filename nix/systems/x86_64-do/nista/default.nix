_: {
  networking.useDHCP = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  users.users.annt = {
    isNormalUser = true;
    initialPassword = "nixos";
    extraGroups = [ "wheel" ];
  };
}
