{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    du-dust
    exa
    fd
    (ripgrep.override { withPCRE2 = true; })
  ];
}
