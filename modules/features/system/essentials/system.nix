{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    curl
    wget

    atool
    rar
    unzip
    zip

    nh
  ];
}
