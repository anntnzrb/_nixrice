# Small everyday toolset (git, fetchers, archivers, nh) for interactive machines.
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # tools
    git
    curl
    wget

    # archiving
    atool
    rar # also provides unrar
    unzip
    zip

    # nix
    nh
  ];
}
