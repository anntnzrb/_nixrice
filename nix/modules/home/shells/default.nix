{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) getExe;

  cfg = config.${namespace}.shells;

  cmd = rec {
    eza = {
      flags = "--color=auto --group-directories-first --icons";
      bin = "${getExe pkgs.eza} ${eza.flags}";
    };

    bat = {
      flags = "--color=auto --theme='Monokai Extended Origin' --style=full";
      bin = "${getExe pkgs.bat} ${bat.flags}";
    };
  };
in
{
  options.${namespace}.shells = with lib.${namespace}; {
    aliases.defaults.enable = mkOptBool';
    sessionVariables = with lib.types; mkOpt' (attrsOf str) { };
  };

  config = {
    home.sessionVariables = {
      NIX_SHELL_PRESERVE_PROMPT = "1";
    } // (lib.optionals (cfg.sessionVariables != null) cfg.sessionVariables);

    home.shellAliases =
      with pkgs;
      (lib.optionals cfg.aliases.defaults.enable {
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
        nix-lockfile-update = "nix flake update --commit-lock-file --option commit-lockfile-summary 'chore(flake): update lockfile'";
        nix-man = "${getExe man} configuration.nix";
        nix-man-hm = "${getExe man} home-configuration.nix";

        # ls/tree => eza
        ls = "${cmd.eza.bin} --sort=Name -agh";
        ll = "${cmd.eza.bin} --sort=Name -aglh";

        tree = "${cmd.eza.bin} -Tgh";
        treea = "${cmd.eza.bin} -Tagh";
        treed = "${cmd.eza.bin} -DTgh";

        # grep => rg (ripgrep)
        grep = "${getExe ripgrep} --color=auto --column --hidden -Hin";

        # cat/less => bat
        cat = "${cmd.bat.bin} -P";
        less = "${cmd.bat.bin}";
      });

    home.packages = with pkgs; [
      bat
      du-dust
      eza
      fd
      (ripgrep.override { withPCRE2 = true; })
    ];
  };
}
