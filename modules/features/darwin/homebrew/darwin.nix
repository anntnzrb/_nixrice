{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.liberion.darwin.homebrew;
  casks = {
    aerospace = "nikitabobko/tap/aerospace";
    aldente = "aldente";
    brave = "brave-browser";
    firefox = "firefox";
    ghostty = "ghostty";
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

  apps = lib.unique cfg.apps;
  pick =
    table: map (app: table.${app}) (builtins.filter (app: table ? ${app}) apps);
  tapOf = cask: lib.concatStringsSep "/" (lib.take 2 (lib.splitString "/" cask));
  taps = lib.unique (
    map tapOf (
      builtins.filter (cask: lib.length (lib.splitString "/" cask) == 3) (pick casks)
    )
  );

  brewPrefix = config.homebrew.prefix;
  brewRepo = "${
    config.nix-homebrew.prefixes.${brewPrefix}.library
  }/.homebrew-is-managed-by-nix";
in
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  options.liberion.darwin.homebrew.apps = lib.liberion.module.mkOpt' (
    lib.types.listOf
      (lib.types.enum (lib.attrNames (casks // masApps)))
  ) [ ];

  config = {
    home-manager.users.${lib.liberion.identity.user}.home.sessionPath =
      lib.mkAfter
        [ "${brewPrefix}/bin" ];

    nix-homebrew = {
      enable = true;
      user = lib.liberion.identity.user;
      autoMigrate = true;
      enableZshIntegration = false;
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

    programs.zsh.interactiveShellInit = ''
      export HOMEBREW_PREFIX="${brewPrefix}";
      export HOMEBREW_CELLAR="${brewPrefix}/Cellar";
      export HOMEBREW_REPOSITORY="${brewRepo}";
      fpath[1,0]="${brewPrefix}/share/zsh/site-functions";
      export FPATH;
      export PATH="${brewPrefix}/bin:${brewPrefix}/sbin''${PATH+:$PATH}";
      [ -z "''${MANPATH-}" ] || { export MANPATH="''${MANPATH%"''${MANPATH##*[!:]}"}"; export MANPATH=":''${MANPATH#"''${MANPATH%%[!:]*}"}"; };
      export INFOPATH="${brewPrefix}/share/info:''${INFOPATH:-}";
    '';

    environment.variables = {
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_EMOJI = "1";
      HOMEBREW_NO_INSECURE_REDIRECT = "1";
    };
  };
}
