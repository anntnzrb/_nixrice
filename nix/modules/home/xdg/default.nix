{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptEnabled';

  cfg = config.${namespace}.xdg;
  homeDir = "${config.home.homeDirectory}";
  libDir = "${homeDir}/lib";
  localDir = "${homeDir}/.local";
in
{
  options.${namespace}.xdg = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    xdg = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isLinux {
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
