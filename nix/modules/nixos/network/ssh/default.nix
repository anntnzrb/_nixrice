{
  config,
  lib,
  format,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.network.ssh;
in
{
  options.${namespace}.network.ssh = {
    enable = mkOptDisabled';
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
        PermitRootLogin =
          if format == "install-iso" then "yes" else "prohibit-password";
        PasswordAuthentication = false;
      };
    };
  };
}
