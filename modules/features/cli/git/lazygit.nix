{ config, lib, ... }:
let
  lazygit = lib.getExe config.programs.lazygit.package;
in
{
  programs.lazygit = {
    enable = true;
    settings = {
      disableStartupPopups = true;
      gui = {
        mouseEvents = true;
        showCommandLog = false;
      };
      spinner.rate = 100;
      git = {
        autoFetch = false;
        autoRefresh = true;
        fetchAll = false;
      };
      refresher = {
        refreshInterval = 3;
        fetchInterval = 180;
      };
    };
  };

  home.shellAliases.gg = lazygit;
}
