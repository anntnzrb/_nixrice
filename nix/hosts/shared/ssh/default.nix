{ pkgs
, ...
}: {
  programs.ssh = {
    package = pkgs.openssh;

    # disable $SSH_ASKPASS
    enableAskPassword = false;

    startAgent = true;
  };

  services.openssh.enable = true;
}
