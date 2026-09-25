# Small common toolset (oulu opts out via disabledModules).
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # tools
    git
    curl
    wget

    # archiving
    atool
    rar
    unrar-wrapper
    unzip
    zip

    # nix
    nh
  ];
}
