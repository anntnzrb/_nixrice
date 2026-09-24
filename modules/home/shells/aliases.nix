{ lib, pkgs, ... }:
let
  inherit (lib) getExe getExe' optionalAttrs;

  inherit (pkgs) coreutils;

  inherit (pkgs.stdenvNoCC.hostPlatform) isLinux;

  /**
    Configuration for eza, a modern replacement for ls.

    # Example

    ```nix
    eza.flags
    =>
    "--color=auto --group-directories-first --icons"

    eza.bin
    =>
    "/run/current-system/sw/bin/eza --color=auto --group-directories-first --icons"
    ```

    # Type

    ```
    { flags :: String, bin :: String }
    ```

    # Fields

    flags
    : CLI flags passed to eza

    bin
    : Full path to eza executable with flags applied
  */
  eza = {
    flags = "--color=auto --group-directories-first --icons";
    bin = "${getExe pkgs.eza} ${eza.flags}";
  };

  /**
    Configuration for bat, a cat clone with syntax highlighting and paging.

    # Example

    ```nix
    bat.flags
    =>
    "--color=auto --style=full"

    bat.bin
    =>
    "/run/current-system/sw/bin/bat --color=auto --style=full"
    ```

    # Type

    ```
    { flags :: String, bin :: String }
    ```

    # Fields

    flags
    : CLI flags passed to bat

    bin
    : Full path to bat executable with flags applied
  */
  bat = {
    flags = "--color=auto --style=full";
    bin = "${getExe pkgs.bat} ${bat.flags}";
  };
in
{
  config.home.shellAliases = {
    # ----------------------------------------------------------------------
    # misc
    # ----------------------------------------------------------------------
    ".." = "cd ..";
    cp = "${getExe' coreutils "cp"} --recursive --interactive --verbose";
    diff = "${getExe' pkgs.diffutils "diff"} --color=auto";
    mkdir = "${getExe' coreutils "mkdir"} --parents --verbose";
    mv = "${getExe' coreutils "mv"} --interactive --verbose";
    rm = "${getExe' coreutils "rm"} --verbose";
    rmfr = "${getExe' coreutils "rm"} --recursive --force --verbose";
    wget = "${getExe pkgs.wget} --no-hsts";
    zip = "${getExe pkgs.zip} --recurse-paths --verbose -9";

    # generate a 16-byte alphanumeric string
    gen-str = "${getExe' coreutils "tr"} --delete --complement 'A-Za-z0-9' < /dev/urandom | ${getExe' coreutils "head"} --bytes 16";

    # empty files management
    dir-empty-print = "${getExe pkgs.fd} --color=always --type empty --type directory .";
    dir-empty-rm = "${getExe pkgs.fd} --color=always --type empty --type directory . --exec ${getExe' coreutils "rmdir"} --verbose {} \;";
    file-empty-print = "${getExe pkgs.fd} --color=always --type empty --type file .";
    file-empty-rm = "${getExe pkgs.fd} --color=always --type empty --type file . --exec ${getExe' coreutils "rm"} --verbose {} \;";

    # network
    tnet = "${getExe pkgs.unixtools.ping} -c 4 8.8.8.8";
    "ip?" =
      "${getExe' pkgs.curlMinimal "curl"} --fail --silent --show-error --location icanhazip.com";
    "local-ip?" = ''
      ${getExe pkgs.unixtools.ifconfig} | ${getExe pkgs.gawk} '/inet / { if ($2 != "127.0.0.1") { print $2; exit } }'
    '';

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
  }
  // optionalAttrs isLinux {
    lsblk = "${getExe' pkgs.util-linux "lsblk"} --all --ascii";
  };
}
