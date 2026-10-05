{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    coreutils
    diffutils
    findutils
    gawk
    getopt
    gnugrep
    gnupatch
    gnused
    gnutar
    gzip
    time
    which
  ];
}
