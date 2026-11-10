{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (inputs.self.clan) inventory;

  cfg = config.liberion.network.sshd;
  userName = lib.liberion.identity.user;

  adminKeys = lib.liberion.adminValues inventory.machines "user-ssh/id_ed25519.pub";
in
{
  imports = [ ./client.nix ];

  options.liberion.network.sshd = with lib.types; {
    extraConfig = mkOpt' str "";
    port = mkOpt' port lib.liberion.identity.sshPort;
    authorizedKeys = mkOpt' (listOf singleLineStr) (
      lib.liberion.authorizedKeys ++ adminKeys
    );
  };

  config.users.users.${userName}.openssh.authorizedKeys.keys = cfg.authorizedKeys;
}
