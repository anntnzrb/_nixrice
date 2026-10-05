{ lib, pkgs, ... }:
let
  inherit (lib) getExe getExe' optionalAttrs;

  inherit (pkgs) coreutils;

  inherit (pkgs.stdenvNoCC.hostPlatform) isLinux;

  ls = "${getExe' coreutils "ls"} --color=auto --group-directories-first --almost-all";
  tree = "${getExe pkgs.tree} -C --dirsfirst";
in
{
  config.home.shellAliases = {
    ".." = "cd ..";
    cp = "${getExe' coreutils "cp"} --recursive --interactive --verbose";
    diff = "${getExe' pkgs.diffutils "diff"} --color=auto";
    mkdir = "${getExe' coreutils "mkdir"} --parents --verbose";
    mv = "${getExe' coreutils "mv"} --interactive --verbose";
    rm = "${getExe' coreutils "rm"} --verbose";
    rmfr = "${getExe' coreutils "rm"} --recursive --force --verbose";
    wget = "${getExe pkgs.wget} --no-hsts";
    zip = "${getExe pkgs.zip} --recurse-paths --verbose -9";

    gen-str = "${getExe' coreutils "tr"} --delete --complement 'A-Za-z0-9' < /dev/urandom | ${getExe' coreutils "head"} --bytes 16";

    dir-empty-print = "${getExe pkgs.fd} --color=always --type empty --type directory .";
    dir-empty-rm = "${getExe pkgs.fd} --color=always --type empty --type directory . --exec ${getExe' coreutils "rmdir"} --verbose {} \;";
    file-empty-print = "${getExe pkgs.fd} --color=always --type empty --type file .";
    file-empty-rm = "${getExe pkgs.fd} --color=always --type empty --type file . --exec ${getExe' coreutils "rm"} --verbose {} \;";

    tnet = "${getExe pkgs.unixtools.ping} -c 4 8.8.8.8";
    "ip?" =
      "${getExe' pkgs.curlMinimal "curl"} --fail --silent --show-error --location icanhazip.com";
    "local-ip?" = ''
      ${getExe pkgs.unixtools.ifconfig} | ${getExe pkgs.gawk} '/inet / { if ($2 != "127.0.0.1") { print $2; exit } }'
    '';

    nix-lockfile-update = "${getExe pkgs.nix} flake update --commit-lock-file --option commit-lockfile-summary 'chore(flake): update lockfile'";

    inherit ls tree;
    ll = "${ls} -l --human-readable";

    treea = "${tree} -a";
    treed = "${tree} -d";
  }
  // optionalAttrs isLinux {
    lsblk = "${getExe' pkgs.util-linux "lsblk"} --all --ascii";
  };
}
