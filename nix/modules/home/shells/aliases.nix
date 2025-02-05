{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;

  eza = {
    flags = "--color=auto --group-directories-first --icons";
    bin = "${getExe pkgs.eza} ${eza.flags}";
  };

  bat = {
    flags = "--color=auto --theme='Monokai Extended Origin' --style=full";
    bin = "${getExe pkgs.bat} ${bat.flags}";
  };
in
{
  config.home.shellAliases = {
    # ----------------------------------------------------------------------
    # misc
    # ----------------------------------------------------------------------
    ".." = "cd ..";
    cp = "cp -Riv";
    diff = "diff --color=auto";
    mkdir = "mkdir -pv";
    lsblk = "lsblk -ai";
    mv = "mv -iv";
    rm = "rm -v";
    rmfr = "rm -Rfv";
    wget = "${getExe pkgs.wget} --no-hsts";
    zip = "${getExe pkgs.zip} -rv";
    tnet = "ping -c 2 8.8.8.8";

    # ----------------------------------------------------------------------
    # nix
    # ----------------------------------------------------------------------
    nix-lockfile-update = "nix flake update --commit-lock-file --option commit-lockfile-summary 'chore(flake): update lockfile'";
    nix-man = "${getExe pkgs.man} configuration.nix";
    nix-man-hm = "${getExe pkgs.man} home-configuration.nix";

    # ----------------------------------------------------------------------
    # coreutils
    # ----------------------------------------------------------------------

    # ls/tree => eza
    ls = "${eza.bin} --sort=Name -agh";
    ll = "${eza.bin} --sort=Name -aglh";

    tree = "${eza.bin} -Tgh";
    treea = "${eza.bin} -Tagh";
    treed = "${eza.bin} -DTgh";

    # grep => rg (ripgrep)
    grep = "${getExe pkgs.ripgrep} --color=auto --column --hidden -Hin";

    # cat/less => bat
    cat = "${bat.bin} -P";
    less = "${bat.bin}";
  };
}
