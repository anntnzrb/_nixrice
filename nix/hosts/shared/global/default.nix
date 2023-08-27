{ pkgs, ... }:
{
  # REVIEW: this might change in the future to suppress annoying db warning
  programs.command-not-found.enable = false;

  environment.systemPackages = with pkgs; [
    git # needed system-wide for flakes
  ];
}
