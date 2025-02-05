{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    getExe'
    ;

  inherit (pkgs.stdenvNoCC)
    isLinux
    ;

  uutils = pkgs.uutils-coreutils-noprefix;

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
    cp = "${getExe' uutils "cp"} --recursive --interactive --verbose";
    diff = "${getExe' pkgs.diffutils "diff"} --color=auto";
    mkdir = "${getExe' uutils "mkdir"} --parents --verbose";
    mv = "${getExe' uutils "mv"} --interactive --verbose";
    rm = "${getExe' uutils "rm"} --verbose";
    rmfr = "${getExe' uutils "rm"} --recursive --force --verbose";
    wget = "${getExe pkgs.wget} --no-hsts";
    zip = "${getExe pkgs.zip "zip"} --recurse-paths --verbose -9";
    tnet = "${getExe pkgs.unixtools.ping} --count 2 8.8.8.8";

    # generate a 16-byte alphanumeric string
    gen-str = "${getExe' uutils "tr"} --delete --complement 'A-Za-z0-9' < /dev/urandom | ${getExe' uutils "head"} --bytes 16";

    # empty files management
    dir-print-empty = "${getExe pkgs.fd} --color=always --type empty --type directory .";
    dir-print-rm = "${getExe pkgs.fd} --color=always --type empty --type directory . --exec ${getExe' uutils "rmdir"} --verbose {} \;";
    file-print-empty = "${getExe pkgs.fd} --color=always --type empty --type file .";
    file-print-rm = "${getExe pkgs.fd} --color=always --type empty --type directory . --exec ${getExe' uutils "rm"} --verbose {} \;";

    # linux
    lsblk = mkIf isLinux "lsblk --all --ascii";

    # ----------------------------------------------------------------------
    # nix
    # ----------------------------------------------------------------------
    nix-lockfile-update = "${getExe pkgs.nix} flake update --commit-lock-file --option commit-lockfile-summary 'chore(flake): update lockfile'";

    # ----------------------------------------------------------------------
    # coreutils
    # ----------------------------------------------------------------------

    # ls => eza
    ls = "${eza.bin} --sort=Name --all --group --header";
    ll = "${eza.bin} --sort=Name --all --group --header --long";

    # tree => eza
    tree = "${eza.bin} --group --header --tree";
    treea = "${eza.bin} --all --group --header --tree";
    treed = "${eza.bin} --group --header --tree --only-dirs";

    # grep => rg (ripgrep)
    grep = "${getExe pkgs.ripgrep} --color=auto --column --hidden --ignore-case --line-number --with-filename";

    # cat/less => bat
    cat = "${bat.bin} --paging=never";
    less = "${bat.bin}";
  };
}
