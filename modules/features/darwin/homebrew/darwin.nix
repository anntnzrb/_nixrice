{
  lib,
  config,
  inputs,
  ...
}:
let
  casks = {
    aldente = "aldente";
    brave = "brave-browser";
    obs = "obs";
    orbstack = "orbstack";
    raycast = "raycast";
    rustdesk = "rustdesk";
    vlc = "vlc";
    vscode = "visual-studio-code";
  };

  masApps = {
    bitwarden.Bitwarden = 1352778147;
    whatsapp."WhatsApp Messenger" = 310633997;
  };

  apps = lib.unique config.liberion.homebrew.apps;
  pick =
    table: map (app: table.${app}) (builtins.filter (app: table ? ${app}) apps);
in
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  options.liberion.homebrew.apps = lib.liberion.module.mkOpt' (lib.types.listOf (
    lib.types.enum (lib.attrNames (casks // masApps))
  )) [ ];

  config = {
    nix-homebrew = {
      enable = true;
      user = lib.liberion.identity.user;
      autoMigrate = true;
    };

    homebrew = {
      enable = true;
      global.autoUpdate = false;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
      };

      casks = pick casks;
      masApps = lib.mergeAttrsList (pick masApps);
    };

    environment.variables = {
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_EMOJI = "1";
      HOMEBREW_NO_INSECURE_REDIRECT = "1";
    };
  };
}
