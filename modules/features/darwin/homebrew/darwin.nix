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
    rustdesk = "rustdesk";
    tinycast = "abue-ammar/tinycast/tinycast";
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
  tapOf = cask: lib.concatStringsSep "/" (lib.take 2 (lib.splitString "/" cask));
  taps = lib.unique (
    map tapOf (
      builtins.filter (cask: lib.length (lib.splitString "/" cask) == 3) (pick casks)
    )
  );
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

      taps = map (name: {
        inherit name;
        trusted = true;
      }) taps;
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
