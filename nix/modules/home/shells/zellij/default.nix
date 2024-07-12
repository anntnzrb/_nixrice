{ config
, lib
, namespace
, ...
}:
let
  cfg = config.${namespace}.shells.zellij;
in
{
  options.${namespace}.shells.zellij = with lib.${namespace}; {
    enable = mkOptBool';
    enableBashIntegration = mkOptEnabled';
    enableZshIntegration = mkOptEnabled';
  };

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      inherit (cfg) enableBashIntegration enableZshIntegration;

      settings = {
        default_mode = "locked";
        ui = {
          pane_frames = {
            hide_session_name = true;
            rounded_corners = true;
          };
        };
      };
    };

    xdg.configFile."zellij/layouts".source = ./layouts;

    home.shellAliases = {
      zll = "zellij";
    };
  };
}
