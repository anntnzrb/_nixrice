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
    attrsOf
    ints
    ;

  cfg = config.${namespace}.homebrew;
in
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  options.${namespace}.homebrew = {
    enable = mkOptDisabled';

    packages = {
      casks = mkOpt' (listOf str) [ ];
      masApps = mkOpt' (attrsOf ints.positive) { };
    };
  };

  config = lib.mkIf cfg.enable {
    nix-homebrew = {
      inherit (cfg) enable;
      enableRosetta = pkgs.system == "aarch64-darwin";
      user = config.${namespace}.user.name;
      autoMigrate = true;
    };

    homebrew = {
      inherit (cfg) enable;
      global.autoUpdate = false;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
      };

      inherit (cfg.packages) casks masApps;
    };

    environment.variables = {
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_EMOJI = "1";
      HOMEBREW_NO_INSECURE_REDIRECT = "1";
    };
  };
}
