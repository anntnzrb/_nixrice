{
  config,
  lib,
  namespace,
  system,
  inputs,
  ...
}:
let
  cfg = config.${namespace}.homebrew;
in
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  options.${namespace}.homebrew =
    with lib.liberion;
    with lib.types;
    {
      enable = mkOptBool';

      packages = {
        casks = mkOpt' (listOf str) [ ];
      };
    };

  config = lib.mkIf cfg.enable {
    nix-homebrew = {
      enable = true;
      enableRosetta = system == "aarch64-darwin";
      user = config.${namespace}.darwin.user.name;
      autoMigrate = true;
    };

    homebrew = {
      enable = true;
      global.autoUpdate = false;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = "zap";
      };

      inherit (cfg.packages) casks;
    };

    environment.variables = {
      HOMEBREW_NO_INSECURE_REDIRECT = "1";
      HOMEBREW_NO_EMOJI = "1";

      # handled by nix; unneeded
      HOMEBREW_NO_ENV_HINTS = "0";
    };
  };
}
