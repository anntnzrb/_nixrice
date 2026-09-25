{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types) listOf str;

  cfg = config.liberion.cli.ssh;
in
{
  # Personal client defaults. Fleet hosts come from the system ssh_config
  # (`liberion.network.ssh`), which ssh reads after this file.
  options.liberion.cli.ssh = {
    enable = mkOptDisabled';
    identityFile = mkOpt' str "~/.ssh/id_ed25519";
    includes = mkOpt' (listOf str) [ ];
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      inherit (cfg) includes;
      settings."*" = {
        IdentityFile = cfg.identityFile;
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
        ConnectTimeout = 10;
        StrictHostKeyChecking = "accept-new";
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin { UseKeychain = "yes"; };
    };
  };
}
