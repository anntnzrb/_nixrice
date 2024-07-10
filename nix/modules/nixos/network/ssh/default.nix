{
  config,
  lib,
  format,
  ...
}:
let
  cfg = config.liberion.network.ssh;
in
{
  options.liberion.network.ssh = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      startAgent = true;
      enableAskPassword = false; # disable $SSH_ASKPASS

      hostKeyAlgorithms = [
        "ssh-ed25519"
        "ssh-rsa"
      ];

      extraConfig = ''
        Host *
          AddKeysToAgent yes
          IdentityFile ~/.ssh/priv
      '';
    };

    services.openssh = {
      enable = true;

      settings = {
        PermitRootLogin = if format == "install-iso" then "yes" else "prohibit-password";
        PasswordAuthentication = false;
      };
    };
  };
}
