{ pkgs, ... }: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    apl386
    fantasque-sans-mono
    fira-code
    fira-code-symbols
    font-awesome
    iosevka
    mononoki
    nerdfonts
  ];
}
