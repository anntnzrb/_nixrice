{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    getExe'
    ;

  inherit (pkgs.stdenvNoCC.hostPlatform)
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
    zip = "${getExe pkgs.zip} --recurse-paths --verbose -9";

    # generate a 16-byte alphanumeric string
    gen-str = "${getExe' uutils "tr"} --delete --complement 'A-Za-z0-9' < /dev/urandom | ${getExe' uutils "head"} --bytes 16";

    # empty files management
    dir-empty-print = "${getExe pkgs.fd} --color=always --type empty --type directory .";
    dir-empty-rm = "${getExe pkgs.fd} --color=always --type empty --type directory . --exec ${getExe' uutils "rmdir"} --verbose {} \;";
    file-empty-print = "${getExe pkgs.fd} --color=always --type empty --type file .";
    file-empty-rm = "${getExe pkgs.fd} --color=always --type empty --type directory . --exec ${getExe' uutils "rm"} --verbose {} \;";

    # network
    tnet = "${getExe pkgs.unixtools.ping} --count 4 8.8.8.8";
    "ip?" =
      "${getExe' pkgs.curlMinimal "curl"} --fail --silent --show-error --location icanhazip.com";
    "local-ip?" = ''
      ${getExe pkgs.unixtools.ifconfig} | ${getExe pkgs.gawk} '/inet / { if ($2 != "127.0.0.1") { print $2; exit } }'
    '';

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
