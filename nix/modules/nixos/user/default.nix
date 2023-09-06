{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOpt';

  cfg = config.liberion.user;
in {
  options.liberion.user = with lib.types; {
    name = mkOpt' str "annt";
    initialPassword = mkOpt' str "pass";
    extraGroups = mkOpt' (listOf str) [];
    packages = mkOpt' (listOf package) [];

    shell = mkOpt' str "bash";
  };

  config = {
    programs.fish.enable = mkIf (cfg.shell == "fish") true;

    # REVIEW: this might change in the future to suppress annoying db warning
    programs.command-not-found.enable = false;

    environment.systemPackages = with pkgs; [
      git

      # archiving
      atool
      p7zip
      rar
      unrar
      unzip
      zip
    ];

    users.users.${cfg.name} = {
      inherit (cfg) name initialPassword extraGroups packages;

      shell = mkIf (cfg.shell == "fish") pkgs.fish;

      isNormalUser = true;
    };
  };
}
