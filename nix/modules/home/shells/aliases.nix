{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) getExe;

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
  config.home.shellAliases =
    with pkgs;
    (lib.optionals config.${namespace}.shells.aliases.defaults.enable {
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
}
