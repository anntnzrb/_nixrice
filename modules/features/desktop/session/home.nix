{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.liberion.desktop.session;
in
{
  options.liberion.desktop.session.apps = {
    terminal = lib.mkPackageOption pkgs "alacritty" { };
    fileManager = lib.mkPackageOption pkgs "pcmanfm" { };
    browser = lib.mkPackageOption pkgs "firefox" { };
  };

  # exported for scripts and configs that read the environment
  # (hyprland.conf, awesome rc.lua, xmonad.hs)
  config.home.sessionVariables = lib.mapAttrs (_: lib.mkDefault) {
    TERMINAL = lib.getExe cfg.apps.terminal;
    FILE = lib.getExe cfg.apps.fileManager;
    BROWSER = lib.getExe cfg.apps.browser;
  };
}
