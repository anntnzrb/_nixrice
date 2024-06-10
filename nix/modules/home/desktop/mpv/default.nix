{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.desktop.mpv;
in
{
  options.liberion.desktop.mpv = with lib.liberion; {
    enable = mkOptBool';
  };
  config = lib.mkIf cfg.enable {
    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [
        uosc
        thumbfast
      ];

      config = {
        # disabled because of uosc script
        osd-bar = false;
        border = false;
      };

      # disabled because of uosc script
      #bindings = import ./bindings.nix;
    };
  };
}
