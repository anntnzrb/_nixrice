{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;
  inherit (lib.liberion) mkOpt';

  cfg = config.liberion.user;
in {
  options.liberion.user = with lib.types; {
    username = mkOption {
      type = str;
      description = "The user's username.";
    };
    homeDirectory = mkOpt' str "/home/${config.liberion.user.username}";
  };

  config = {
    home = {
      inherit (cfg) username homeDirectory;

      sessionVariables = {
        BROWSER = "firefox";
        EDITOR = "nvim";
        FILE = "pcmanfm";
        TERMINAL = "alacritty";

        NIX_SHELL_PRESERVE_PROMPT = "1";
      };

      shellAliases = {
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
    };

    systemd.user.startServices = "sd-switch";
  };
}
