{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.desktop.feh;
in
{
  options.${namespace}.desktop.feh = {
    enable = mkOptBool';
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
