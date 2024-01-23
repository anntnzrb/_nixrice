{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.liberion.desktop.feh;
in
{
  options.liberion.desktop.feh = with lib.liberion; {
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
      mimeType = [ "image/png" "image/jpg" "image/svg+xml" ];
    };
  };
}
