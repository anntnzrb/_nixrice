{ config
, lib
, ...
}:
let
  cfg = config.liberion.cli.btop;
in
{
  options.liberion.cli.btop = {
    enable = lib.mkEnableOption "btop";
  };

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;

      settings = {
        vim_keys = true;
        rounded_corners = true;
        update_ms = 2000;
        clock_format = "%H:%M";
        temp_scale = "celsius";

        # proc
        proc_tree = true;
        proc_sorting = "memory";

        # net
        net_auto = false;
        net_sync = false;
        net_download = 100;
        net_upload = 100;
      };
    };
  };
}
