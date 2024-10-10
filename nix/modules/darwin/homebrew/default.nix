{
  lib,
  config,
  inputs,
  namespace,
  system,
  ...
}:
let
  cfg = config.${namespace}.homebrew;
in
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  options.${namespace}.homebrew = with lib.liberion; {
    enable = mkOptBool';

    packages = {
      casks = with lib.types; mkOpt' (listOf str) [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    nix-homebrew = {
      enable = true;
      enableRosetta = system == "aarch64-darwin";
      user = config.${namespace}.darwin.user.name;
      autoMigrate = true;
    };

    homebrew =
      let
        autoUpgrade = true;
      in
      {
        enable = true;
        global.autoUpdate = autoUpgrade;
        onActivation = {
          autoUpdate = autoUpgrade;
          upgrade = autoUpgrade;
          cleanup = "zap";
        };

        inherit (cfg.packages) casks;
      };

    environment.variables = {
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_EMOJI = "1";
      HOMEBREW_NO_INSECURE_REDIRECT = "1";

      # handled by nix; unneeded
      HOMEBREW_NO_ENV_HINTS = "0";
    };
  };
}
