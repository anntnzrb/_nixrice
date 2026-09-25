# XDG base and user dirs baseline (Linux homes).
{
  config,
  lib,
  pkgs,
  ...
}:
let

  homeDir = config.home.homeDirectory;
  libDir = "${homeDir}/lib";
in
{
  xdg = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isLinux {
    enable = true;
    mime.enable = true;
    mimeApps.enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;

      desktop = "${homeDir}/desktop";
      documents = libDir;
      download = "${homeDir}/downloads";
      music = "${libDir}/music";
      pictures = "${libDir}/pics";
      publicShare = "${libDir}/public";
      templates = "${libDir}/templates";
      videos = "${libDir}/vids";
    };
  };
}
