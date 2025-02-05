{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.cli.btop;
in
{
  options.${namespace}.cli.btop = {
    enable = mkOptBool';
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

    services.sxhkd = {
      keybindings = {
        "super + Return ; i" = "${config.home.sessionVariables.TERMINAL} -e btop";
      };
    };
  };
}
