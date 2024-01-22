{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.shells;
in
{
  options.liberion.shells = {
    defaults = {
      enable = lib.mkEnableOption "sane shell defaults";
    };

    sessionVariables = lib.mkOption {
      type = with lib.types; attrsOf str;
      description = "Environment variables to always set at login. Refer to home.sessionVariables";
    };

    altCoreUtils = {
      enable = lib.mkEnableOption "alternative core utilities";
    };
  };

  config = {
    home = {
      sessionVariables =
        let
          defaults = lib.mkIf cfg.defaults.enable {
            NIX_SHELL_PRESERVE_PROMPT = "1";
          };
        in
        lib.mkMerge [
          { }
          defaults
          cfg.sessionVariables
        ];

      shellAliases =
        let
          defaults = lib.mkIf cfg.defaults.enable {
            ".." = "cd ..";
            cp = "cp -Riv";
            diff = "diff --color=auto";
            mkdir = "mkdir -pv";
            lsblk = "lsblk -ai";
            mv = "mv -iv";
            rm = "rm -v";
            rmfr = "rm -Rfv";
            wget = "wget --no-hsts";
            zip = "zip -rv";

            mannixos = "man configuration.nix";
            manhm = "man home-configuration.nix";
          };

          altCoreUtils = lib.mkIf cfg.altCoreUtils.enable {
            # ls/tree => eza
            ls = "eza --color=automatic --group-directories-first --icons --sort=Name -Fagh";
            ll = "eza --color=automatic --group-directories-first --icons --sort=Name -Faglh";

            tree = "eza --color=automatic --group-directories-first --icons -FTgh";
            treea = "eza --color=automatic --group-directories-first --icons -FTagh";
            treed = "eza --color=automatic --icons -DFTgh";

            # grep => rg
            grep = "rg --color=auto --column --hidden -Hin";

            # cat/less => bat
            cat = "bat --color=auto --theme='Monokai Extended Origin' --style=full -P";
            less = "bat --color=auto --theme='Monokai Extended Origin' --style=full";
          };
        in
        lib.mkMerge [
          { }
          defaults
          altCoreUtils
        ];

      packages = with pkgs; lib.mkIf cfg.altCoreUtils.enable [
        bat
        du-dust
        eza
        fd
        (ripgrep.override { withPCRE2 = true; })
      ];
    };
  };
}
