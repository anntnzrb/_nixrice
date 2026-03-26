{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (lib.${namespace}.fs) getModuleFiles;

  cfg = config.${namespace}.shells.tmux;
in
{
  imports = getModuleFiles { path = ./.; };

  options.${namespace}.shells.tmux = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      inherit (cfg) enable;

      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      customPaneNavigationAndResize = true;
      disableConfirmationPrompt = true;
      escapeTime = 0;
      focusEvents = true;
      mouse = true;
      newSession = false;
      shortcut = "b";
      terminal = "tmux-256color";
      extraConfig = ''
        set -g status-position top

        set -g status-style bg=default,fg=default
        set -g status-justify left
        set -g automatic-rename off
        set -g status-left '[#S] '
        set -g status-right ' '
        setw -g window-status-format '#I:#W#F'
        setw -g window-status-current-format '#[bold]#I:#W#F'

        bind '"' split-window -v -c '#{pane_current_path}'
        bind % split-window -h -c '#{pane_current_path}'
        bind c new-window -c '#{pane_current_path}'

        bind -N "Reload tmux configuration" R source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "Config reloaded!"
      '';
    };
  };
}
