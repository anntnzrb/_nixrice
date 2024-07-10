{ config
, lib
, pkgs
, ...
}:
let
  homeDir = "${config.home.homeDirectory}";
  libDir = "${homeDir}/lib";
  localDir = "${homeDir}/.local";
in
{
  config = {
    xdg = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;

      cacheHome = "${homeDir}/.cache";
      configHome = "${homeDir}/.config";
      dataHome = "${localDir}/share";
      stateHome = "${localDir}/state";

      mime.enable = true;
      mimeApps.enable = true;

      userDirs = {
        enable = true;
        createDirectories = true;

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
  };
}
