{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOptEnabled' on;

  cfg = config.liberion.xdg;
  homeDir = "${config.home.homeDirectory}";
  libDir = "${homeDir}/lib";
  localDir = "${homeDir}/.local";
in
{
  options.liberion.xdg = {
    enable = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    xdg = lib.mkIf pkgs.stdenvNoCC.hostPlatform.isLinux {
      inherit (cfg) enable;

      cacheHome = "${homeDir}/.cache";
      configHome = "${homeDir}/.config";
      dataHome = "${localDir}/share";
      stateHome = "${localDir}/state";

      mime = on;
      mimeApps = on;

      userDirs = on // {
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
  };
}
