{
  pkgs,
  config,
  ...
}: let
  cfg = config.liberion.ssh;
in {
  config = {
    programs.ssh = {
      package = pkgs.openssh;

      # disable $SSH_ASKPASS
      enableAskPassword = false;

      startAgent = true;
    };

    services.openssh.enable = true;
  };
}
