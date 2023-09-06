{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.pcmanfm;
in {
  options.liberion.desktop.pcmanfm = {
    enable = mkOptBool' false;

    settings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = {
        config = {
          bm_open_method = 0;
        };

        volume = {
          mount_on_startup = 1;
          mount_removable = 1;
          autorun = 1;
        };

        ui = {
          always_show_tabs = 1;
          media_in_new_tab = 0;
          close_on_unmount = 1;
          side_pane_mode = "places";
          view_mode = "icon";
          show_hidden = 1;
          show_statusbar = 1;
          pathbar_mode_buttons = 0;
        };
      };
      description = "Settings for PCManFM.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.pcmanfm];

    xdg.configFile = {
      "pcmanfm" = {
        enable = true;
        target = "pcmanfm/pcmanfm.conf";
        text = lib.generators.toINI {} cfg.settings;
      };
    };
  };
}
