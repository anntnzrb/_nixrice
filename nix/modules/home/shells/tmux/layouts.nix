{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptEnabled'
    ;

  cfg = config.${namespace}.shells.tmux;
  cockpitCfg = cfg.layouts.cockpit;

  cockpitScriptPath = "${config.xdg.configHome}/tmux/scripts/cockpit-reset.sh";
in
{
  options.${namespace}.shells.tmux.layouts.cockpit = {
    enable = mkOptEnabled';
    bind = mkOpt' lib.types.str "M";
  };

  config = lib.mkIf (cfg.enable && cockpitCfg.enable) {
    xdg.configFile."tmux/scripts/cockpit-reset.sh" = {
      source = ./scripts/cockpit-reset.sh;
      executable = true;
    };

    programs.tmux.extraConfig = lib.mkAfter ''
      bind -N "Reset current window to cockpit layout" ${cockpitCfg.bind} command-prompt -I "#W" -p "Project name" "run-shell '${cockpitScriptPath} \"%%\" \"#{window_id}\" \"#{pane_current_path}\"'"
    '';
  };
}
