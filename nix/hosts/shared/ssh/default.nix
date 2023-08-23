{ pkgs
, ...
}: {
  programs.ssh = {
    package = pkgs.openssh;

    # disable $SSH_ASKPASS
    enableAskPassword = false;
  };
}
