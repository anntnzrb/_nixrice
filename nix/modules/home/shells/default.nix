{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.shells;
in
{
  options.liberion.shells = with lib.liberion; with lib.types; {
    defaults = {
      enable = mkOptBool';
    };

    sessionVariables = mkOpt' (attrsOf str) { };

    altCoreUtils = {
      enable = mkOptBool';
    };
  };

  config = with lib; {
    home = {
      sessionVariables =
        let
          defaults = mkIf cfg.defaults.enable {
            NIX_SHELL_PRESERVE_PROMPT = "1";
          };
        in
        mkMerge [
          { }
          defaults
          cfg.sessionVariables
        ];

      shellAliases = with pkgs;
        let
          defaults = mkIf cfg.defaults.enable {
            ".." = "cd ..";
            cp = "cp -Riv";
            diff = "diff --color=auto";
            mkdir = "mkdir -pv";
            lsblk = "lsblk -ai";
            mv = "mv -iv";
            rm = "rm -v";
            rmfr = "rm -Rfv";
            wget = "${getExe wget} --no-hsts";
            zip = "${getExe zip} -rv";

            # nix
            nix-lockfile-update = "nix flake update --commit-lock-file --commit-lockfile-summary 'chore(flake): update lockfile'";
            nix-man = "${getExe man} configuration.nix";
            nix-man-hm = "${getExe man} home-configuration.nix";
          };

          altCoreUtils =
            let
              commonEzaFlags = "--color=auto --group-directories-first --icons";
            in
            mkIf cfg.altCoreUtils.enable {
              # ls/tree => eza
              ls = "${getExe eza} ${commonEzaFlags} --sort=Name -agh";
              ll = "${getExe eza} ${commonEzaFlags} --sort=Name -aglh";

              tree = "${getExe eza} ${commonEzaFlags} -Tgh";
              treea = "${getExe eza} ${commonEzaFlags} -Tagh";
              treed = "${getExe eza} ${commonEzaFlags} -DTgh";

              # grep => rg (ripgrep)
              grep = "${getExe ripgrep} --color=auto --column --hidden -Hin";

              # cat/less => bat
              cat = "${getExe bat} --color=auto --theme='Monokai Extended Origin' --style=full -P";
              less = "${getExe bat} --color=auto --theme='Monokai Extended Origin' --style=full";
            };
        in
        mkMerge [
          { }
          defaults
          altCoreUtils
        ];

      packages = with pkgs; mkIf cfg.altCoreUtils.enable [
        bat
        du-dust
        eza
        fd
        (ripgrep.override { withPCRE2 = true; })
      ];
    };
  };
}
