{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) listOf str;

  cfg = config.liberion.cli.ssh;
in
{
  options.liberion.cli.ssh = {
    identityFile = mkOpt' str "~/.ssh/id_ed25519";
    includes = mkOpt' (listOf str) [ ];
  };

  config.programs.ssh = {
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
}
