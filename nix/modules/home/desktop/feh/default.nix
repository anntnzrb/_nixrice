{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.desktop.feh;
in
{
  options.${namespace}.desktop.feh = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.feh = {
      enable = true;
    };

    xdg.desktopEntries.feh = {
      name = "feh";
      genericName = "Image Viewer";
      exec = "${lib.getExe pkgs.feh} --auto-zoom --scale-down -B black -PVd %F";
      categories = [ "Application" ];
      mimeType = [
        "image/png"
        "image/jpg"
        "image/svg+xml"
      ];
    };
  };
}
