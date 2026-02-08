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

  scriptDir = "tmux/scripts";
  scriptName = "cockpit-reset.sh";
  scriptRelPath = "${scriptDir}/${scriptName}";
  scriptSource = ./scripts/cockpit-reset.sh;
  cockpitScriptPath = "${config.xdg.configHome}/${scriptRelPath}";
  bindDescription = "Reset current window to cockpit layout";
  promptLabel = "Project name";
in
{
  options.${namespace}.shells.tmux.layouts.cockpit = {
    enable = mkOptEnabled';
    bind = mkOpt' lib.types.str "M";
  };

  config = lib.mkIf (cfg.enable && cockpitCfg.enable) {
    xdg.configFile."${scriptRelPath}" = {
      source = scriptSource;
      executable = true;
    };

    programs.tmux.extraConfig = lib.mkAfter ''
      bind -N "${bindDescription}" ${cockpitCfg.bind} command-prompt -I "#W" -p "${promptLabel}" "run-shell '${cockpitScriptPath} \"%%\" \"#{window_id}\" \"#{pane_current_path}\"'"
    '';
  };
}
