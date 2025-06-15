{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptDisabled'
    ;
  inherit (lib.types)
    listOf
    str
    ;

  cfg = config.${namespace}.homebrew;
in
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  options.${namespace}.homebrew = {
    enable = mkOptDisabled';

    packages = {
      casks = mkOpt' (listOf str) [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    nix-homebrew = {
      enable = true;
      enableRosetta = pkgs.system == "aarch64-darwin";
      user = config.${namespace}.user.name;
      autoMigrate = true;
    };

    homebrew = {
      enable = true;
      global.autoUpdate = false;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
      };

      inherit (cfg.packages) casks;
    };

    environment.variables = {
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_EMOJI = "1";
      HOMEBREW_NO_INSECURE_REDIRECT = "1";
    };
  };
}
